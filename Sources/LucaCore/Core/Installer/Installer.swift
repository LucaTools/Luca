//  Installer.swift

import Foundation

public struct Installer {
    
    enum InstallerError: Error, LocalizedError {
        case unknownFileType(String)
        
        var errorDescription: String? {
            switch self {
            case .unknownFileType(let file):
                return "Unknown file type for file \(file))."
            }
        }
    }
    
    private let fileManager: FileManaging
    private let printer: Printing
    private let binaryFinder: BinaryFinding
    private let checksumValidator: ChecksumValidating
    private let architectureValidator: ArchitectureValidating
    private let fileDownloader: FileDownloading
    private let downloader: Downloading
    private let permissionManager: PermissionManaging
    private let symLinker: SymLinking
    private let ignoreArchitectureCheck: Bool
    
    public init(fileManager: FileManaging, ignoreArchitectureCheck: Bool, printer: Printing) {
        self.fileManager = fileManager
        self.printer = printer
        self.binaryFinder = BinaryFinder(fileManager: fileManager)
        self.checksumValidator = ChecksumValidator(fileManager: fileManager)
        self.architectureValidator = ArchitectureValidator(fileManager: fileManager)
        self.fileDownloader = FileDownloader(session: .shared)
        self.downloader = Downloader(fileDownloader: fileDownloader)
        self.permissionManager = PermissionManager(fileManager: fileManager)
        self.symLinker = SymLinker(fileManager: fileManager)
        self.ignoreArchitectureCheck = ignoreArchitectureCheck
    }
    
    public func install(installationType: InstallationType) async throws {
        let dataDownloader = DataDownloader(session: .shared)
        let releaseInfoProvider = ReleaseInfoProvider(dataDownloader: dataDownloader)
        let specLoader = SpecLoader(fileManager: .default)
        let toolFactory = ToolFactory(releaseInfoProvider: releaseInfoProvider, specLoader: specLoader)
        printer.printFormatted("\(.raw("🧠 Detecting tools to install..."))")
        let tools = try await toolFactory.toolsForInstallationType(installationType)
        printer.printFormatted("\(.raw("🏃‍♂️ Installing tools for the current project."))")
        printer.printFormatted("")
        try await installTools(tools)
    }
    
    // MARK: - Private
    
    private func installTools(_ tools: [Tool]) async throws {
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
    
    // MARK: - Private
    
    private func reinstall(_ tool: Tool) throws {
        printer.printFormatted("\(.raw("👀 Tool \(tool.name) version \(tool.version) is already installed."))")
        let installationDestination = fileManager.toolsFolder
            .appending(components: tool.name, tool.version)
        let binaryPath = try binaryFinder.findBinary(atPath: installationDestination.path)
        let enrichedTool = EnrichedTool(
            name: tool.name,
            version: tool.version,
            url: tool.url,
            binaryPath: binaryPath,
            desiredBinaryName: tool.desiredBinaryName,
            checksum: tool.checksum,
            algorithm: tool.algorithm
        )
        try permissionManager.setExecutablePermission(for: enrichedTool)
        let symLink = try symLinker.setSymLink(for: enrichedTool)
        printer.printFormatted("\(.raw("🔗 Recreated symlink at \(symLink.path)"))")
        
        printer.printFormatted("\(.success("🙌 Tool \(tool.name) version \(tool.version) installed for the current project."))")
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
        
        printer.printFormatted("\(.success("🙌 Tool \(tool.name) version \(tool.version) installed for the current project."))")
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
        
        let enrichedTool = EnrichedTool(
            name: tool.name,
            version: tool.version,
            url: tool.url,
            binaryPath: binaryPath,
            desiredBinaryName: nil,
            checksum: tool.checksum,
            algorithm: tool.algorithm
        )
        try permissionManager.setExecutablePermission(for: enrichedTool)
        
        printer.printFormatted("\(.raw("💾 Installed \(tool.name) version \(tool.version) at \(installationDestination.path)"))")
        
        let symLink = try symLinker.setSymLink(for: enrichedTool)
        printer.printFormatted("\(.raw("🔗 Created symlink to \(symLink.path)"))")
    }
    
    private func installExecutable(tool: Tool, downloadedFile: URL, installationDestination: URL) throws {
        try fileManager.createDirectory(at: installationDestination, withIntermediateDirectories: true)
        let binaryName: String = {
            if let binaryName = tool.desiredBinaryName { return binaryName }
            return tool.name
        }()
        let destinationFile = installationDestination
            .appending(components: binaryName)
        try fileManager.moveItem(at: downloadedFile, to: destinationFile)
        
        try validateArchitectureIfNeeded(
            tool: tool,
            binaryPath: destinationFile.path,
            installationDestination: installationDestination
        )

        let enrichedTool = EnrichedTool(
            name: tool.name,
            version: tool.version,
            url: tool.url,
            binaryPath: binaryName,
            desiredBinaryName: binaryName,
            checksum: nil,
            algorithm: nil
        )
        try permissionManager.setExecutablePermission(for: enrichedTool)
        
        printer.printFormatted("\(.raw("💾 Installed \(tool.name) version \(tool.version) at \(installationDestination.path)"))")
        
        let symLink = try symLinker.setSymLink(for: enrichedTool)
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
        if ignoreArchitectureCheck {
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
