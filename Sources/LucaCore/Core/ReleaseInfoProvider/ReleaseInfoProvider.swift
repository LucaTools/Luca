//  ReleaseInfoProvider.swift

import Foundation

struct ReleaseInfoProvider: ReleaseInfoProviding {
    
    private let macOSKeywords = ["darwin", "macos", "mac", "osx", "x86_64", "amd64", "arm64", "universal", "artifactbundle"]
    
    enum ReleaseInfoProviderError: Error, LocalizedError, Equatable {
        case apiError(String)
        case cannotIdentifyAsset([ReleaseAsset])
        case releaseNotFound(URL)
        
        var errorDescription: String? {
            switch self {
            case .apiError(let message):
                return "API error: \(message)."
            case .cannotIdentifyAsset(let assets):
                return "Cannot identify suitable asset in list of release assets: \(assets.map { $0.name })."
            case .releaseNotFound(let url):
                return "Release not found at \(url.absoluteString)."
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
        if let asset = findBestMatch(in: zipAssets) {
            return asset
        }
        
        let executableAssets = assets.filter { URL(fileURLWithPath: $0.name).pathExtension.isEmpty }
        if let asset = findBestMatch(in: executableAssets) {
            return asset
        }

        throw ReleaseInfoProviderError.cannotIdentifyAsset(assets)
    }

    private func findBestMatch(in assets: [ReleaseAsset]) -> ReleaseAsset? {
        let sortedAssets = assets.sorted { asset1, asset2 in
            let count1 = macOSKeywords.filter { asset1.name.lowercased().contains($0) }.count
            let count2 = macOSKeywords.filter { asset2.name.lowercased().contains($0) }.count
            return count1 > count2
        }
        
        return sortedAssets.first { asset in
            macOSKeywords.contains { keyword in
                asset.name.lowercased().contains(keyword)
            }
        }
    }
}
