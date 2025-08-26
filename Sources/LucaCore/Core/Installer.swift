//  Installer.swift

import Foundation

/// Handles downloading, unpacking and activating (via symlink) versioned tools.
final public class Installer {

    /// Errors surfaced during install operations.
    enum MainError: Error, LocalizedError, CustomNSError {
        case invalidUrl(String)      // Malformed zip URL.
        case missingBinary(String)   // Expected binary not found after unzip.

        var errorDescription: String? {
            switch self {
            case .invalidUrl(let url):
                return "URL '\(url)' is invalid."
            case .missingBinary(let binaryName):
                return "Binary '\(binaryName)' is missing."
            }
        }

        var errorCode: Int {
            switch self {
            case .invalidUrl: return 101
            case .missingBinary: return 102
            }
        }

        static var errorDomain: String { "io.github.luca.installer" }
    }

    // Dependencies / environment.
    private let fileManager: FileManaging
    private let homeDirectory: URL                 // Home directory (where versioned installs live under .luca/tools).
    private let currentWorkingDirectory: URL       // Directory whose .luca/active holds symlinks.

    /// Session used for remote downloads (injected for testing if desired).
    var session: URLSession { URLSession.shared }

    public init(fileManager: FileManaging) {
        self.fileManager = fileManager
        self.homeDirectory = fileManager.homeDirectoryForCurrentUser
        self.currentWorkingDirectory = URL(fileURLWithPath: fileManager.currentDirectoryPath)
    }

    /// Root folder for all installed versions.
    var toolsFolder: URL {
        homeDirectory
            .appending(components: Constants.toolFolder, Constants.toolsFolder)
    }

    /// Folder containing symlinks to currently active binaries (per working directory).
    var activeFolder: URL {
        currentWorkingDirectory
            .appending(components: Constants.toolFolder, Constants.activeFolder)
    }

    /// Ensure each tool in the spec is installed and symlinked (idempotent; re‑running is safe).
    public func install(from spec: Spec) async throws {
        for tool in spec.tools {
            if isToolInstalled(tool) {
                print("Tool \(tool.name) version \(tool.version) is already installed.")
            } else {
                print("Installing '\(tool.name)' (version \(tool.version)).")
                let filePath = try await download(tool)
                try unzip(tool, zipFilePath: filePath)
                print("Installation completed.\n")
            }
            try setSymLink(tool)
        }
    }

    // MARK: - Download

    /// Download the remote zip for the tool and move it to a stable temp path.
    private func download(_ tool: Tool) async throws -> URL {
        guard let url = URL(string: tool.zipUrl) else {
            throw MainError.invalidUrl(tool.zipUrl)
        }
        print("Downloading....")
        let (tempDownloadURL, _) = try await session.download(from: url)
        let tempURL = fileManager.temporaryDirectory
            .appendingPathComponent(tool.description)
            .appendingPathExtension("zip")
        if fileManager.fileExists(atPath: tempURL.path) {
            try fileManager.removeItem(at: tempURL)
        }
        try fileManager.moveItem(at: tempDownloadURL, to: tempURL)
        return tempURL
    }

    // MARK: - Tool

    /// Unzip the downloaded archive into the versioned installation folder.
    private func unzip(_ tool: Tool, zipFilePath: URL) throws {
        print("Unzipping...")
        let destinationFolder = toolsFolder
            .appending(components: tool.name, tool.version)

        try fileManager.createDirectory(at: destinationFolder, withIntermediateDirectories: true)

        // Use native Process instead of ShellOut; arguments array avoids shell interpretation/escaping issues.
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/env")
        process.arguments = ["unzip", "-q", "-o", zipFilePath.path, "-d", destinationFolder.path]

        let stdoutPipe = Pipe()
        let stderrPipe = Pipe()
        process.standardOutput = stdoutPipe
        process.standardError = stderrPipe

        try process.run()
        process.waitUntilExit()

        if process.terminationStatus != 0 {
            let errData = stderrPipe.fileHandleForReading.readDataToEndOfFile()
            let errStr = String(data: errData, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? "Unknown error"
            throw NSError(domain: "io.github.luca.installer.unzip", code: Int(process.terminationStatus), userInfo: [NSLocalizedDescriptionKey: "Failed to unzip archive: \(errStr)"])
        }
    }

    /// Create (or replace) the symlink for the tool's binary in the active folder.
    private func setSymLink(_ tool: Tool) throws {
        let symLinkFile = activeFolder
            .appending(component: tool.binaryName)

        // Support nested binaryPath components.
        let destinationFile = toolsFolder
            .appending(components: tool.name, tool.version)
            .appending(path: tool.binaryPath)

        if !fileManager.fileExists(atPath: destinationFile.path) {
            throw MainError.missingBinary(tool.binaryName)
        }
        if fileManager.fileExists(atPath: symLinkFile.path) {
            try fileManager.removeItem(at: symLinkFile)
        }
        print("Creating symlink to", destinationFile.path, "\n")
        try fileManager.createDirectory(at: activeFolder, withIntermediateDirectories: true)
        try fileManager.createSymbolicLink(at: symLinkFile, withDestinationURL: destinationFile)
    }

    // MARK: - Install checks

    /// Returns true if the versioned binary already exists locally.
    private func isToolInstalled(_ tool: Tool) -> Bool {
        let expectedBinaryLocation = toolsFolder
            .appending(components: tool.name, tool.version)
            .appending(path: tool.binaryPath)
        return fileManager.fileExists(atPath: expectedBinaryLocation.path)
    }
}
