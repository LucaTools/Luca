//  Unarchiver.swift

import Foundation

/// Extracts tool archives to their installation destination.
///
/// The `Unarchiver` handles extracting ZIP and tar.gz archives using
/// system utilities (`unzip` and `tar`).
///
/// ## Supported Formats
///
/// - **ZIP** - Extracted using `/usr/bin/unzip`
/// - **tar.gz** - Extracted using `/usr/bin/tar`
///
/// ## Topics
///
/// ### Extracting Archives
/// - ``unarchive(filePath:installationDestination:)``
struct Unarchiver: Unarchiving {
    
    enum UnarchiverError: Error, LocalizedError {
        case unrecognizedFileType(String)
        case notAnArchive(String)
        case failedToUnarchive(Error)
        case unsafeArchiveEntry(String)

        var errorDescription: String? {
            switch self {
            case .unrecognizedFileType(let file):
                return "Unrecognized file type \(file)."
            case .notAnArchive(let file):
                return "File \(file) is not an archive."
            case .failedToUnarchive(let error):
                return "Failed to unarchive with error '\(error)'."
            case .unsafeArchiveEntry(let entry):
                return "Refusing to extract archive: it contains an unsafe entry ('\(entry)') that could write outside the installation directory."
            }
        }
    }
    
    private let fileManager: UnarchiverFileManaging
    private let fileTypeDetector: FileTypeDetector
    
    init(fileManager: UnarchiverFileManaging, fileTypeDetector: FileTypeDetector) {
        self.fileManager = fileManager
        self.fileTypeDetector = fileTypeDetector
    }
    
    /// Extracts an archive to the specified destination.
    ///
    /// - Parameters:
    ///   - filePath: The path to the archive file.
    ///   - installationDestination: The directory to extract files into.
    /// - Throws: ``UnarchiverError/unrecognizedFileType(_:)`` if the file type
    ///   cannot be determined, ``UnarchiverError/notAnArchive(_:)`` if the file
    ///   is an executable, or ``UnarchiverError/failedToUnarchive(_:)`` if
    ///   extraction fails.
    func unarchive(filePath: URL, installationDestination: URL) throws {
        try fileManager.createDirectory(at: installationDestination, withIntermediateDirectories: true)

        guard let fileType = try fileTypeDetector.detectFileType(at: filePath) else {
            throw UnarchiverError.unrecognizedFileType(filePath.path)
        }

        if case .executable = fileType {
            throw UnarchiverError.notAnArchive(filePath.path)
        }

        // Reject archives whose contents could escape the installation directory before
        // extracting anything. `unzip` (and, on some platforms, `tar`) will happily create a
        // symbolic link and then write *through* it, letting a crafted archive drop files into
        // arbitrary locations such as `~/.ssh` or shell start-up files (the "Zip Slip" / tar
        // symlink-escape class of attacks). Validating up front means a malicious archive never
        // reaches the extraction step.
        try validateArchiveEntries(filePath: filePath, fileType: fileType)

        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/env")

        switch fileType {
        case .zip:
            process.arguments = ["unzip", "-q", "-o", filePath.path, "-d", installationDestination.path]
        case .targz:
            process.arguments = ["tar", "-xzf", filePath.path, "-C", installationDestination.path]
        case .executable:
            throw UnarchiverError.notAnArchive(filePath.path)
        }

        let stdoutPipe = Pipe()
        let stderrPipe = Pipe()
        process.standardOutput = stdoutPipe
        process.standardError = stderrPipe

        try process.run()
        process.waitUntilExit()

        if process.terminationStatus != 0 {
            let errData = stderrPipe.fileHandleForReading.readDataToEndOfFile()
            let errStr = String(data: errData, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? "Unknown error"
            let error = NSError(
                domain: "io.github.luca.unarchiver",
                code: Int(process.terminationStatus),
                userInfo: [NSLocalizedDescriptionKey: "Failed to unarchive: \(errStr)"]
            )
            throw UnarchiverError.failedToUnarchive(error)
        }
    }

    // MARK: - Safety Validation

    /// Inspects an archive's table of contents and throws if any entry could escape the
    /// installation directory.
    ///
    /// An entry is rejected when it is a symbolic or hard link, uses an absolute path, or
    /// contains a `..` path component.
    ///
    /// - Parameters:
    ///   - filePath: The archive to inspect.
    ///   - fileType: The detected archive type (``FileType/zip`` or ``FileType/targz``).
    /// - Throws: ``UnarchiverError/unsafeArchiveEntry(_:)`` for an unsafe entry, or
    ///   ``UnarchiverError/failedToUnarchive(_:)`` if the archive cannot be listed.
    private func validateArchiveEntries(filePath: URL, fileType: FileType) throws {
        let nameArguments: [String]
        let verboseArguments: [String]
        switch fileType {
        case .zip:
            nameArguments = ["unzip", "-Z1", filePath.path]
            verboseArguments = ["unzip", "-Z", filePath.path]
        case .targz:
            nameArguments = ["tar", "-tzf", filePath.path]
            verboseArguments = ["tar", "-tvzf", filePath.path]
        case .executable:
            return
        }

        // Reject absolute paths and parent-directory traversal by entry name.
        for rawName in try listOutput(arguments: nameArguments) {
            let name = rawName.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !name.isEmpty else { continue }
            if name.hasPrefix("/") || name.hasPrefix("~") {
                throw UnarchiverError.unsafeArchiveEntry(name)
            }
            if name.components(separatedBy: "/").contains("..") {
                throw UnarchiverError.unsafeArchiveEntry(name)
            }
        }

        // Reject symbolic links ("l") and hard links ("h"). Both `unzip -Z` and `tar -tv`
        // print a Unix-style mode column whose first character encodes the entry type.
        for line in try listOutput(arguments: verboseArguments) {
            guard let typeChar = line.drop(while: { $0 == " " }).first else { continue }
            if typeChar == "l" || typeChar == "h" {
                throw UnarchiverError.unsafeArchiveEntry(line.trimmingCharacters(in: .whitespacesAndNewlines))
            }
        }
    }

    /// Runs a listing command and returns its standard output split into lines.
    ///
    /// - Parameter arguments: The arguments passed to `/usr/bin/env`.
    /// - Returns: The standard-output lines produced by the command.
    /// - Throws: ``UnarchiverError/failedToUnarchive(_:)`` if the command cannot be run or
    ///   exits with a non-zero status (e.g. a corrupt archive).
    private func listOutput(arguments: [String]) throws -> [String] {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/env")
        process.arguments = arguments

        let stdoutPipe = Pipe()
        let stderrPipe = Pipe()
        process.standardOutput = stdoutPipe
        process.standardError = stderrPipe

        do {
            try process.run()
        } catch {
            throw UnarchiverError.failedToUnarchive(error)
        }

        // Read before waiting to avoid deadlocking on a full pipe buffer.
        let data = stdoutPipe.fileHandleForReading.readDataToEndOfFile()
        process.waitUntilExit()

        guard process.terminationStatus == 0 else {
            let errData = stderrPipe.fileHandleForReading.readDataToEndOfFile()
            let errStr = String(data: errData, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? "Unknown error"
            let error = NSError(
                domain: "io.github.luca.unarchiver",
                code: Int(process.terminationStatus),
                userInfo: [NSLocalizedDescriptionKey: "Failed to list archive contents: \(errStr)"]
            )
            throw UnarchiverError.failedToUnarchive(error)
        }

        let output = String(data: data, encoding: .utf8) ?? ""
        return output.split(separator: "\n", omittingEmptySubsequences: false).map(String.init)
    }
}
