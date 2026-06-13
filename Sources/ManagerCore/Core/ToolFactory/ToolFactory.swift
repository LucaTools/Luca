//  ToolFactory.swift

import Foundation
import LucaFoundation

/// Creates ``Tool`` instances from various installation type descriptions.
struct ToolFactory {

    enum ToolFactoryError: Error, LocalizedError, Equatable {
        case invalidIdentifierFormat(String)
        case invalidRepositoryFormat(String)
        
        var errorDescription: String? {
            switch self {
            case .invalidIdentifierFormat(let value):
                return "Invalid tool format. Expected 'organization/repository@version'. Got \(value)."
            case .invalidRepositoryFormat(let value):
                return "Invalid repository format. Expected 'organization/repository'. Got \(value)."
            }
        }
    }
    
    private let releaseInfoProvider: ReleaseInfoProviding
    private let specLoader: SpecLoading
    
    init(releaseInfoProvider: ReleaseInfoProviding, specLoader: SpecLoading) {
        self.releaseInfoProvider = releaseInfoProvider
        self.specLoader = specLoader
    }
    
    // MARK: - Internal
    
    /// Returns the list of tools to install for the given installation type.
    /// - Parameter installationType: Specifies whether to read from a spec file or install a single tool directly.
    func toolsForInstallationType(_ installationType: ToolInstallationType) async throws -> [Tool] {
        switch installationType {
        case .spec(let specPath):
            return try specLoader.loadSpec(at: specPath).tools ?? []
        case .individual(let identifier, let asset, let binaryPath, let desiredBinaryName, let checksum, let algorithm):
            let tool = try await toolForIdentifier(
                identifier,
                asset: asset,
                binaryPath: binaryPath,
                desiredBinaryName: desiredBinaryName,
                checksum: checksum,
                algorithm: algorithm
            )
            return [tool]
        case .individualInline(let name, let version, let url, let binaryPath, let desiredBinaryName, let checksum, let algorithm):
            return [Tool(
                name: name,
                version: version,
                url: url,
                binaryPath: binaryPath,
                desiredBinaryName: desiredBinaryName,
                checksum: checksum,
                algorithm: algorithm,
                ignoreArchCheck: nil,
                ignoreUnsafeArchiveEntries: nil
            )]
        }
    }
    
    // MARK: - Private
    
    private func toolForIdentifier(_ identifier: String, asset: String?, binaryPath: String?, desiredBinaryName: String?, checksum: String?, algorithm: ChecksumAlgorithm?) async throws -> Tool {
        let components = identifier.split(separator: "@")
        guard components.count == 2,
              let version = components.last.map(String.init) else {
            throw ToolFactoryError.invalidIdentifierFormat(identifier)
        }
        
        let repoComponent = String(components[0])
        let repoComponents = repoComponent.split(separator: "/")
        guard repoComponents.count == 2,
              let organization = repoComponents.first.map(String.init),
              let repository = repoComponents.last.map(String.init) else {
            throw ToolFactoryError.invalidRepositoryFormat(repoComponent)
        }
        
        let release = Release(organization: organization, repository: repository, version: version)
        
        let assetFilename = try await {
            if let asset { return asset }
            return try await releaseInfoProvider.platformAsset(for: release).name
        }()
        
        let releaseAssetUrl = try GitHubReleaseURLFactory().makeReleaseAssetURL(
            release: release,
            asset: assetFilename
        )
        
        return Tool(
            name: repository,
            version: version,
            url: releaseAssetUrl,
            binaryPath: binaryPath,
            desiredBinaryName: desiredBinaryName,
            checksum: checksum,
            algorithm: algorithm,
            ignoreArchCheck: nil,
            ignoreUnsafeArchiveEntries: nil
        )
    }
}
