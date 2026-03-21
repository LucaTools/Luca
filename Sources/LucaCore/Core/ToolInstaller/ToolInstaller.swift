//  ToolInstaller.swift

import Foundation

/// Downloads, validates, and installs a single development tool from its remote URL.
///
/// `ToolInstaller` handles the complete per-tool installation pipeline:
/// 1. Downloads the release archive or executable from the tool's URL
/// 2. Validates the checksum (if provided)
/// 3. Detects the file type and routes to archive or executable installation
/// 4. Validates binary architecture compatibility
/// 5. Sets executable permissions and creates a symlink
struct ToolInstaller: ToolInstalling {

    enum ToolInstallerError: Error, LocalizedError, Equatable {
        case unknownFileType(String)

        var errorDescription: String? {
            switch self {
            case .unknownFileType(let file):
                return "Unknown file type for file \(file)."
            }
        }
    }

    private let fileManager: FileManaging
    private let downloader: Downloading
    private let binaryFinder: BinaryFinding
    private let checksumValidator: ChecksumValidating
    private let architectureValidator: ArchitectureValidating
    private let permissionManager: PermissionManaging
    private let symLinker: SymLinking
    private let printer: Printing
    private let ignoreArchitectureCheck: Bool

    init(
        fileManager: FileManaging,
        ignoreArchitectureCheck: Bool,
        printer: Printing,
        downloader: Downloading? = nil
    ) {
        self.fileManager = fileManager
        self.ignoreArchitectureCheck = ignoreArchitectureCheck
        self.printer = printer
        self.binaryFinder = BinaryFinder(fileManager: fileManager)
        self.checksumValidator = ChecksumValidator(fileManager: fileManager)
        self.architectureValidator = ArchitectureValidator(fileManager: fileManager)
        self.permissionManager = PermissionManager(fileManager: fileManager)
        self.symLinker = SymLinker(fileManager: fileManager)
        self.downloader = downloader ?? Downloader(fileDownloader: FileDownloader(session: .shared))
    }

    // MARK: - ToolInstalling

    /// Installs the given tool by downloading, validating, and linking it.
    ///
    /// - Parameter tool: The ``Tool`` to download, validate, and install.
    func install(tool: Tool) async throws {
        printer.printFormatted("\(.raw("⬇️ Downloading \(tool.name) version \(tool.version)..."))")

        let downloadedFile = try await downloader.downloadRelease(at: tool.url)

        if let checksum = tool.checksum {
            printer.printFormatted("\(.raw("📋 Validating checksum for \(tool.name) version \(tool.version)..."))")
            try checksumValidator.validate(checksum: checksum, for: downloadedFile.path, using: tool.algorithm ?? .sha256)
        } else {
            printer.printFormatted("\(.raw("📋 Skipping checksum validation for \(tool.name) version \(tool.version)..."))")
        }

        let fileTypeDetector = FileTypeDetector(fileManager: fileManager)
        guard let fileType = try fileTypeDetector.detectFileType(at: downloadedFile) else {
            throw ToolInstallerError.unknownFileType(downloadedFile.path)
        }

        let installationDestination = fileManager.toolsFolder
            .appending(components: tool.name, tool.version)

        switch fileType {
        case .zip, .targz: try installArchive(tool: tool, downloadedFile: downloadedFile, installationDestination: installationDestination)
        case .executable: try installExecutable(tool: tool, downloadedFile: downloadedFile, installationDestination: installationDestination)
        }

        printer.printFormatted("\(.primary("🙌 Tool \(tool.name) version \(tool.version) installed for the current project."))")
    }

    // MARK: - Private

    private func installArchive(tool: Tool, downloadedFile: URL, installationDestination: URL) throws {
        printer.printFormatted("\(.raw("📦 Unarchiving \(tool.name) version \(tool.version)..."))")

        let fileTypeDetector = FileTypeDetector(fileManager: fileManager)

        let unarchiver = Unarchiver(fileManager: fileManager, fileTypeDetector: fileTypeDetector)
        try unarchiver.unarchive(filePath: downloadedFile, installationDestination: installationDestination)

        let binaryPath: String = try {
            if let binaryPath = tool.binaryPath { return binaryPath }
            return try binaryFinder.findBinary(atPath: installationDestination.path)
        }()

        let fullBinaryPath = installationDestination.appending(path: binaryPath).path
        try validateArchitectureIfNeeded(
            tool: tool,
            binaryPath: fullBinaryPath,
            installationDestination: installationDestination
        )

        let resolvedTool = Tool(
            name: tool.name,
            version: tool.version,
            url: tool.url,
            binaryPath: binaryPath,
            desiredBinaryName: nil,
            checksum: tool.checksum,
            algorithm: tool.algorithm,
            ignoreArchCheck: nil
        )
        try permissionManager.setExecutablePermission(for: resolvedTool)

        printer.printFormatted("\(.raw("💾 Installed \(tool.name) version \(tool.version) at \(installationDestination.path)"))")

        let symLink = try symLinker.setSymLink(for: resolvedTool)
        printer.printFormatted("\(.raw("🔗 Created symlink to \(symLink.path)"))")
    }

    private func installExecutable(tool: Tool, downloadedFile: URL, installationDestination: URL) throws {
        try fileManager.createDirectory(at: installationDestination, withIntermediateDirectories: true)
        let binaryName = tool.effectiveBinaryPath
        let destinationFile = installationDestination
            .appending(components: binaryName)
        try fileManager.moveItem(at: downloadedFile, to: destinationFile)

        try validateArchitectureIfNeeded(
            tool: tool,
            binaryPath: destinationFile.path,
            installationDestination: installationDestination
        )

        let resolvedTool = Tool(
            name: tool.name,
            version: tool.version,
            url: tool.url,
            binaryPath: binaryName,
            desiredBinaryName: binaryName,
            checksum: nil,
            algorithm: nil,
            ignoreArchCheck: nil
        )
        try permissionManager.setExecutablePermission(for: resolvedTool)

        printer.printFormatted("\(.raw("💾 Installed \(tool.name) version \(tool.version) at \(installationDestination.path)"))")

        let symLink = try symLinker.setSymLink(for: resolvedTool)
        printer.printFormatted("\(.raw("🔗 Created symlink to \(symLink.path)"))")
    }

    private func validateArchitectureIfNeeded(tool: Tool, binaryPath: String, installationDestination: URL) throws {
        let effectiveIgnore = tool.ignoreArchCheck ?? ignoreArchitectureCheck
        if effectiveIgnore {
            printer.printFormatted("\(.raw("🔍 Skipping architecture validation for \(tool.name) version \(tool.version)..."))")
        } else {
            printer.printFormatted("\(.raw("🔍 Validating architecture for \(tool.name) version \(tool.version)..."))")
            do {
                try architectureValidator.validate(binaryPath: binaryPath)
            } catch {
                printer.printFormatted("\(.raw("🗑️ Cleaning up incompatible tool \(tool.name) version \(tool.version)..."))")
                try? fileManager.removeItem(at: installationDestination)
                throw error
            }
        }
    }
}
