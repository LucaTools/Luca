//  Installer.swift

import Foundation
import Noora

public struct Installer {
    
    private let fileManager: FileManaging
    private let noora: Noorable
    private let binaryFinder: BinaryFinding
    private let fileDownloader: FileDownloading
    private let downloader: Downloading
    private let permissionManager: PermissionManaging
    private let symLinker: SymLinking
    
    public init(fileManager: FileManaging, noora: Noorable = Noora()) {
        self.fileManager = fileManager
        self.noora = noora
        self.binaryFinder = BinaryFinder(fileManager: fileManager)
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
        let tools = try await toolFactory.toolsForInstallationType(installationType)
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
        
        print(noora.format("\(.success("🚀 All tools have been installed for the current project."))"))
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
            binaryPath: binaryPath
        )
        try permissionManager.setExecutablePermission(for: enrichedTool)
        let symLink = try symLinker.setSymLink(for: enrichedTool)
        print(noora.format("\(.raw("🔗 Recreated symlink at \(symLink.path)"))"))
        
        print(noora.format("\(.success("🙌 Tool \(tool.name) version \(tool.version) installed for the current project."))"))
    }
    
    private func install(_ tool: Tool) async throws {
        print(noora.format("\(.raw("⬇️ Downloading \(tool.name) version \(tool.version)..."))"))
        
        let localFile = try await downloader.downloadArchive(at: tool.url)
        
        print(noora.format("\(.raw("📦 Unarchiving \(tool.name) version \(tool.version)..."))"))
        
        let unarchiver = Unarchiver(fileManager: fileManager)
        let installationDestination = try unarchiver.unarchive(tool, filePath: localFile)
        
        print(noora.format("\(.raw("💾 Installed \(tool.name) version \(tool.version) at \(installationDestination.path)"))"))
        
        let binaryPath: String = try {
            if let binaryPath = tool.binaryPath { return binaryPath }
            return try binaryFinder.findBinary(atPath: installationDestination.path)
        }()
        
        let enrichedTool = EnrichedTool(
            name: tool.name,
            version: tool.version,
            url: tool.url,
            binaryPath: binaryPath
        )
        try permissionManager.setExecutablePermission(for: enrichedTool)
        
        let symLink = try symLinker.setSymLink(for: enrichedTool)
        print(noora.format("\(.raw("🔗 Created symlink to \(symLink.path)"))"))
        
        print(noora.format("\(.success("🙌 Tool \(tool.name) version \(tool.version) installed for the current project."))"))
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
