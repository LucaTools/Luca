//  Unarchiver.swift

import Foundation

struct Unarchiver: Unarchiving {
    
    enum UnarchiverError: Error, LocalizedError {
        case unrecognisedFileType(String)
        case notAnArchive(String)
        case failedToUnarchive(Error)
        
        var errorDescription: String? {
            switch self {
            case .unrecognisedFileType(let file):
                return "Unrecognised file type \(file)."
            case .notAnArchive(let file):
                return "File \(file) is not an archive."
            case .failedToUnarchive(let error):
                return "Failed to unarchive with error '\(error)'."
            }
        }
    }
    
    private let fileManager: UnarchiverFileManaging
    private let fileTypeDetector: FileTypeDetector
    
    init(fileManager: UnarchiverFileManaging, fileTypeDetector: FileTypeDetector) {
        self.fileManager = fileManager
        self.fileTypeDetector = fileTypeDetector
    }
    
    func unarchive(filePath: URL, installationDestination: URL) throws {
        try fileManager.createDirectory(at: installationDestination, withIntermediateDirectories: true)

        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/env")
        
        guard let fileType = try fileTypeDetector.detectFileType(at: filePath) else {
            throw UnarchiverError.unrecognisedFileType(filePath.path)
        }
        
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
}
