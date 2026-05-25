//  GitHubReleaseURLFactory.swift

import Foundation

/// Constructs GitHub URLs for downloading release assets and querying the releases API.
struct GitHubReleaseURLFactory {

    enum GitHubReleaseURLFactoryError: Error, LocalizedError, Equatable {
        case cannotConstructUrl(Release)
        
        var errorDescription: String? {
            switch self {
            case .cannotConstructUrl(let release):
                return "Cannot construct URL for organization '\(release.organization)', repository '\(release.repository)', version '\(release.version)'."
            }
        }
    }
    
    /// Builds the direct download URL for a specific release asset.
    /// - Parameters:
    ///   - release: The release to target.
    ///   - asset: The asset filename (e.g. `"tool-1.0.0-macos.zip"`).
    /// - Returns: The download URL for the asset.
    func makeReleaseAssetURL(release: Release, asset: String) throws -> URL {
        guard let url = URL(string: "https://github.com/\(release.organization)/\(release.repository)/releases/download/\(release.version)/\(asset)") else {
            throw GitHubReleaseURLFactoryError.cannotConstructUrl(release)
        }
        return url
    }
    
    /// Builds the GitHub API URL for fetching release information by tag.
    /// - Parameter release: The release whose metadata to fetch.
    /// - Returns: The GitHub REST API URL for the release.
    func makeApiReleaseURL(release: Release) throws -> URL {
        guard let url = URL(string: "https://api.github.com/repos/\(release.organization)/\(release.repository)/releases/tags/\(release.version)") else {
            throw GitHubReleaseURLFactoryError.cannotConstructUrl(release)
        }
        return url
    }
}
