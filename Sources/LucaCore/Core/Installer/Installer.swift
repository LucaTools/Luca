//  Installer.swift

import Foundation
import Noora

public struct Installer {
    
    private let fileManager: FileManaging
    private let noora: Noorable
    private let binaryFinder: BinaryFinding
    private let checksumValidator: ChecksumValidating
    private let fileDownloader: FileDownloading
    private let downloader: Downloading
    private let permissionManager: PermissionManaging
    private let symLinker: SymLinking
    
    public init(fileManager: FileManaging, noora: Noorable = Noora()) {
        self.fileManager = fileManager
        self.noora = noora
        self.binaryFinder = BinaryFinder(fileManager: fileManager)
        self.checksumValidator = ChecksumValidator(fileManager: fileManager)
        self.fileDownloader = FileDownloader(session: .shared)
        self.downloader = Downloader(fileDownloader: fileDownloader)
        self.permissionManager = PermissionManager(fileManager: fileManager)
        self.symLinker = SymLinker(fileManager: fileManager)
    }
    
    public func install(installationType: InstallationType) async throws {
        let dataDownloader = DataDownloader(session: .shared)
        let releaseInfoProvider = ReleaseInfoProvider(dataDownloader: dataDownloader)
        let specLoader = SpecLoader(fileManager: .default)
        let toolFactory = ToolFactory(releaseInfoProvider: releaseInfoProvider, specLoader: specLoader)
        print(noora.format("\(.raw("🧠 Detecting tools to install..."))"))
        let tools = try await toolFactory.toolsForInstallationType(installationType)
        print(noora.format("\(.raw("🏃‍♂️ Installing tools for the current project."))"))
        print()
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
            print()
        }
        
        print(noora.format("\(.success("🚀 Tools have been installed for the current project."))"))
    }
    
    // MARK: - Private
    
    private func reinstall(_ tool: Tool) throws {
        print(noora.format("\(.raw("👀 Tool \(tool.name) version \(tool.version) is already installed."))"))
        let installationDestination = fileManager.toolsFolder
            .appending(components: tool.name, tool.version)
        let binaryPath = try binaryFinder.findBinary(atPath: installationDestination.path)
        let enrichedTool = EnrichedTool(
            name: tool.name,
            version: tool.version,
            url: tool.url,
            binaryPath: binaryPath,
            checksum: tool.checksum,
            algorithm: tool.algorithm
        )
        try permissionManager.setExecutablePermission(for: enrichedTool)
        let symLink = try symLinker.setSymLink(for: enrichedTool)
        print(noora.format("\(.raw("🔗 Recreated symlink at \(symLink.path)"))"))
        
        print(noora.format("\(.success("🙌 Tool \(tool.name) version \(tool.version) installed for the current project."))"))
    }
    
    private func install(_ tool: Tool) async throws {
        print(noora.format("\(.raw("⬇️ Downloading \(tool.name) version \(tool.version)..."))"))
        
        let downloadedFile = try await downloader.downloadRelease(at: tool.url)

        if let checksum = tool.checksum {
            print(noora.format("\(.raw("📋 Validating checksum for \(tool.name) version \(tool.version)..."))"))
            try checksumValidator.validate(checksum: checksum, for: downloadedFile.path, using: tool.algorithm ?? .sha256)
        } else {
            print(noora.format("\(.raw("📋 Skipping checksum validation for \(tool.name) version \(tool.version)..."))"))
        }

        let fileTypeDetector = FileTypeDetector(fileManager: fileManager)
        let fileType = try fileTypeDetector.detectFileType(at: downloadedFile)
        
        let installationDestination = fileManager.toolsFolder
            .appending(components: tool.name, tool.version)
        
        switch fileType {
        case .zip: try installZip(tool: tool, downloadedFile: downloadedFile, installationDestination: installationDestination)
        case .executable: try installExecutable(tool: tool, downloadedFile: downloadedFile, installationDestination: installationDestination)
        case .unknown: print("Warning: Unknown file type. Attempting to treat as executable.")
        }
        
        print(noora.format("\(.success("🙌 Tool \(tool.name) version \(tool.version) installed for the current project."))"))
    }
    
    private func installZip(tool: Tool, downloadedFile: URL, installationDestination: URL) throws {
        print(noora.format("\(.raw("📦 Unarchiving \(tool.name) version \(tool.version)..."))"))
        
        let unarchiver = Unarchiver(fileManager: fileManager)
        try unarchiver.unarchive(filePath: downloadedFile, installationDestination: installationDestination)
        
        let binaryPath: String = try {
            if let binaryPath = tool.binaryPath { return binaryPath }
            return try binaryFinder.findBinary(atPath: installationDestination.path)
        }()
        
        let enrichedTool = EnrichedTool(
            name: tool.name,
            version: tool.version,
            url: tool.url,
            binaryPath: binaryPath,
            checksum: tool.checksum,
            algorithm: tool.algorithm
        )
        try permissionManager.setExecutablePermission(for: enrichedTool)
        
        print(noora.format("\(.raw("💾 Installed \(tool.name) version \(tool.version) at \(installationDestination.path)"))"))
        
        let symLink = try symLinker.setSymLink(for: enrichedTool)
        print(noora.format("\(.raw("🔗 Created symlink to \(symLink.path)"))"))
    }
    
    private func installExecutable(tool: Tool, downloadedFile: URL, installationDestination: URL) throws {
        try fileManager.createDirectory(at: installationDestination, withIntermediateDirectories: true)
        let binaryName = tool.name
        let destinationFile = installationDestination
            .appending(components: binaryName)
        try fileManager.moveItem(at: downloadedFile, to: destinationFile)
        let enrichedTool = EnrichedTool(
            name: tool.name,
            version: tool.version,
            url: tool.url,
            binaryPath: binaryName,
            checksum: nil,
            algorithm: nil
        )
        try permissionManager.setExecutablePermission(for: enrichedTool)
        
        print(noora.format("\(.raw("💾 Installed \(tool.name) version \(tool.version) at \(installationDestination.path)"))"))
        
        let symLink = try symLinker.setSymLink(for: enrichedTool)
        print(noora.format("\(.raw("🔗 Created symlink to \(symLink.path)"))"))
    }

    private func isToolInstalled(_ tool: Tool) -> Bool {
        let expectedBinaryLocation: URL = {
            let versionFolder = fileManager.toolsFolder
                .appending(components: tool.name, tool.version)
            if let binaryPath = tool.binaryPath {
                return versionFolder
                    .appending(components: binaryPath)
            } else {
                return versionFolder
            }
        }()
        return fileManager.fileExists(atPath: expectedBinaryLocation.path)
    }
}
