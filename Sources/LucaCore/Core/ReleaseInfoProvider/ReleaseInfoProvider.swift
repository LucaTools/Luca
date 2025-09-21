//  ReleaseInfoProvider.swift

import Foundation

struct ReleaseInfoProvider: ReleaseInfoProviding {
    
    private let macOSKeywords = ["darwin", "macos", "mac", "osx", "x86_64", "amd64", "arm64", "universal"]
    
    enum ReleaseInfoProviderError: Error, LocalizedError, Equatable {
        case apiError(String)
        case cannotIdentifyAsset([ReleaseAsset])
        case releaseNotFound(URL)
        
        var errorDescription: String? {
            switch self {
            case .apiError(let message):
                return "API error: \(message)."
            case .cannotIdentifyAsset(let assets):
                return "Cannot identify suitable asset in list of release assets: (\(assets))."
            case .releaseNotFound(let url):
                return "Release not found at \(url.path)."
            }
        }
    }
            
    private var dataDownloader: DataDownloading
    
    init(dataDownloader: DataDownloading) {
        self.dataDownloader = dataDownloader
    }
    
    // MARK: - Internal
    
    func macOSAsset(for release: Release) async throws -> ReleaseAsset {
        let releaseInfo = try await fetchReleaseInfo(release: release)
        return try findMacOSAsset(in: releaseInfo.assets)
    }
    
    // MARK: - Private
    
    private func fetchReleaseInfo(release: Release) async throws -> ReleaseInfo {
        let releaseUrl = try GitHubReleaseURLFactory().makeApiReleaseURL(release: release)
        
        var request = URLRequest(url: releaseUrl)
        request.setValue("application/vnd.github.v3+json", forHTTPHeaderField: "Accept")
        request.setValue("luca.tools.cli", forHTTPHeaderField: "User-Agent")
        
        let (data, response) = try await dataDownloader.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw ReleaseInfoProviderError.apiError("Invalid response from GitHub")
        }
        
        if httpResponse.statusCode == 404 {
            throw ReleaseInfoProviderError.releaseNotFound(releaseUrl)
        }
        
        if httpResponse.statusCode != 200 {
            throw ReleaseInfoProviderError.apiError("HTTP error \(httpResponse.statusCode)")
        }
        
        return try JSONDecoder().decode(ReleaseInfo.self, from: data)
    }
    
    private func findMacOSAsset(in assets: [ReleaseAsset]) throws -> ReleaseAsset {
        let zipAssets = assets.filter { $0.name.lowercased().hasSuffix(".zip") }
        
        let sortedZipAssets = zipAssets.sorted { asset1, asset2 in
            let count1 = macOSKeywords.filter { asset1.name.lowercased().contains($0) }.count
            let count2 = macOSKeywords.filter { asset2.name.lowercased().contains($0) }.count
            return count1 > count2
        }
        
        let potentialMacOSAssets = sortedZipAssets.filter { asset in
            macOSKeywords.contains { keyword in
                asset.name.lowercased().contains(keyword)
            }
        }

        guard let macOSAsset = potentialMacOSAssets.first else {
            throw ReleaseInfoProviderError.cannotIdentifyAsset(assets)
        }

        return macOSAsset
    }
}
