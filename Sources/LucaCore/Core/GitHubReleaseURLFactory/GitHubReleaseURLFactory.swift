//  GitHubReleaseURLFactory.swift

import Foundation

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
    
    func makeReleaseAssetURL(release: Release, asset: String) throws -> URL {
        guard let url = URL(string: "https://github.com/\(release.organization)/\(release.repository)/releases/download/\(release.version)/\(asset)") else {
            throw GitHubReleaseURLFactoryError.cannotConstructUrl(release)
        }
        return url
    }
    
    func makeApiReleaseURL(release: Release) throws -> URL {
        guard let url = URL(string: "https://api.github.com/repos/\(release.organization)/\(release.repository)/releases/tags/\(release.version)") else {
            throw GitHubReleaseURLFactoryError.cannotConstructUrl(release)
        }
        return url
    }
}
