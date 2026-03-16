//  Installer.swift

import Foundation
import Noora

/// Downloads, verifies, and installs tools from remote URLs.
///
/// The `Installer` orchestrates the complete installation process for development tools:
/// 1. Downloads the release archive or executable from the specified URL
/// 2. Validates the checksum (if provided)
/// 3. Extracts archives or handles executables
/// 4. Validates architecture compatibility
/// 5. Sets executable permissions
/// 6. Creates symlinks in the project's `.luca/tools/` directory
///
/// ## Usage
///
/// ```swift
/// let installer = Installer(
///     fileManager: FileManager.default,
///     ignoreArchitectureCheck: false,
///     printer: Printer()
/// )
/// try await installer.install(installationType: .spec(path: lucafilePath))
/// ```
///
/// ## Topics
///
/// ### Installing Tools
/// - ``install(installationType:)``
///
/// ### Installation Types
/// - ``InstallationType``
public struct Installer {
    
    enum InstallerError: Error, LocalizedError, Equatable {
        case unknownFileType(String)
        
        var errorDescription: String? {
            switch self {
            case .unknownFileType(let file):
                return "Unknown file type for file \(file)."
            }
        }
    }
    
    private let fileManager: FileManaging
    private let printer: Printing
    private let binaryFinder: BinaryFinding
    private let checksumValidator: ChecksumValidating
    private let architectureValidator: ArchitectureValidating
    private let downloader: Downloading
    private let permissionManager: PermissionManaging
    private let symLinker: SymLinking
    private let linkedToolsLister: LinkedToolsLister
    private let unlinker: Unlinker
    private let ignoreArchitectureCheck: Bool
    private let quiet: Bool
    private let noora: Noorable
    
    public init(
        fileManager: FileManaging,
        ignoreArchitectureCheck: Bool,
        quiet: Bool = false,
        printer: Printing,
        downloader: Downloading? = nil,
        noora: Noorable = Noora()
    ) {
        self.fileManager = fileManager
        self.printer = printer
        self.binaryFinder = BinaryFinder(fileManager: fileManager)
        self.checksumValidator = ChecksumValidator(fileManager: fileManager)
        self.architectureValidator = ArchitectureValidator(fileManager: fileManager)
        self.downloader = downloader ?? Downloader(fileDownloader: FileDownloader(session: .shared))
        self.permissionManager = PermissionManager(fileManager: fileManager)
        self.symLinker = SymLinker(fileManager: fileManager)
        self.linkedToolsLister = LinkedToolsLister(fileManager: fileManager)
        self.unlinker = Unlinker(fileManager: fileManager, printer: printer)
        self.ignoreArchitectureCheck = ignoreArchitectureCheck
        self.quiet = quiet
        self.noora = noora
    }
    
    /// Installs tools based on the specified installation type.
    ///
    /// - Parameter installationType: Specifies how to determine which tools to install.
    ///   Can be either `.spec` to read from a Lucafile, or `.github` to install directly
    ///   from a GitHub release.
    /// - Throws: An error if downloading, extracting, or linking fails.
    public func install(installationType: InstallationType) async throws {
        if quiet {
            try await installQuietly(installationType: installationType)
        } else {
            try await installVerbose(installationType: installationType)
        }
    }
    
    // MARK: - Private
    
    private func installQuietly(installationType: InstallationType) async throws {
        try await noora.progressStep(
            message: "Installing tools",
            successMessage: "Tools have been installed for the current project",
            errorMessage: "Failed to install tools",
            showSpinner: true
        ) { updateMessage in
            let dataDownloader = DataDownloader(session: .shared)
            let releaseInfoProvider = ReleaseInfoProvider(dataDownloader: dataDownloader)
            let specLoader = SpecLoader(fileManager: .default)
            let toolFactory = ToolFactory(releaseInfoProvider: releaseInfoProvider, specLoader: specLoader)
            
            updateMessage("Detecting tools to install")
            let tools = try await toolFactory.toolsForInstallationType(installationType)
            
            // Unlink orphaned tools only when installing from a spec
            if case .spec = installationType {
                try unlinkOrphanedTools(specTools: tools)
            }
            
            for tool in tools {
                updateMessage("Installing \(tool.name) \(tool.version)")
                if isToolInstalled(tool) {
                    try reinstall(tool)
                } else {
                    try await install(tool)
                }
            }
        }
    }
    
    private func installVerbose(installationType: InstallationType) async throws {
        let dataDownloader = DataDownloader(session: .shared)
        let releaseInfoProvider = ReleaseInfoProvider(dataDownloader: dataDownloader)
        let specLoader = SpecLoader(fileManager: .default)
        let toolFactory = ToolFactory(releaseInfoProvider: releaseInfoProvider, specLoader: specLoader)
        
        printer.printFormatted("\(.info("🧠 Detecting tools to install..."))")
        
        let tools = try await toolFactory.toolsForInstallationType(installationType)
        
        // Unlink orphaned tools only when installing from a spec
        if case .spec = installationType {
            try unlinkOrphanedTools(specTools: tools)
        }
        
        printer.printFormatted("\(.info("🏃‍♂️ Installing tools for the current project."))")
        printer.printFormatted("")

        for tool in tools {
            if isToolInstalled(tool) {
                try reinstall(tool)
            } else {
                try await install(tool)
            }
            printer.printFormatted("")
        }
        
        printer.printFormatted("\(.success("🚀 Tools have been installed for the current project."))")
    }

    private func reinstall(_ tool: Tool) throws {
        printer.printFormatted("\(.raw("👀 Tool \(tool.name) version \(tool.version) is already installed."))")
        let installationDestination = fileManager.toolsFolder
            .appending(components: tool.name, tool.version)
        let binaryPath = try binaryFinder.findBinary(atPath: installationDestination.path)
        let resolvedTool = Tool(
            name: tool.name,
            version: tool.version,
            url: tool.url,
            binaryPath: binaryPath,
            desiredBinaryName: tool.desiredBinaryName,
            checksum: tool.checksum,
            algorithm: tool.algorithm,
            ignoreArchCheck: tool.ignoreArchCheck
        )
        try permissionManager.setExecutablePermission(for: resolvedTool)
        let symLink = try symLinker.setSymLink(for: resolvedTool)
        printer.printFormatted("\(.raw("🔗 Recreated symlink at \(symLink.path)"))")
        
        printer.printFormatted("\(.primary("🙌 Tool \(tool.name) version \(tool.version) installed for the current project."))")
    }
    
    private func install(_ tool: Tool) async throws {
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
            throw InstallerError.unknownFileType(downloadedFile.path)
        }
        
        let installationDestination = fileManager.toolsFolder
            .appending(components: tool.name, tool.version)
        
        switch fileType {
        case .zip, .targz: try installArchive(tool: tool, downloadedFile: downloadedFile, installationDestination: installationDestination)
        case .executable: try installExecutable(tool: tool, downloadedFile: downloadedFile, installationDestination: installationDestination)
        }
        
        printer.printFormatted("\(.primary("🙌 Tool \(tool.name) version \(tool.version) installed for the current project."))")
    }
    
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

    private func isToolInstalled(_ tool: Tool) -> Bool {
        let expectedBinaryLocation: URL = {
            let versionFolder = fileManager.toolsFolder
                .appending(components: tool.name, tool.version)
            if let binaryPath = tool.binaryPath {
                return versionFolder
                    .appending(components: binaryPath)
            }
            if let desiredBinaryName = tool.desiredBinaryName {
                return versionFolder
                    .appending(component: desiredBinaryName)
            }
            return versionFolder
        }()
        return fileManager.fileExists(atPath: expectedBinaryLocation.path)
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
    
    private func unlinkOrphanedTools(specTools: [Tool]) throws {
        let linkedTools = try linkedToolsLister.linkedTools()
        
        // Build a set of tool names from spec for efficient lookup
        let specToolNames: Set<String> = Set(specTools.map(\.name))
        
        // Find linked tools that are not in the spec
        let orphanedTools = linkedTools.filter { linkedTool in
            !specToolNames.contains(linkedTool.name)
        }
        
        // Unlink each orphaned tool
        for orphanedTool in orphanedTools {
            printer.printFormatted("\(.raw("🧹 Unlinking \(orphanedTool.binaryName) (removed from spec)..."))")
            try unlinker.unlink(symlink: orphanedTool.binaryName)
        }
    }
}
