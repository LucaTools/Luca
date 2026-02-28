//  ReleaseInfoProvider.swift

import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

struct ReleaseInfoProvider: ReleaseInfoProviding {
    
    #if os(Linux)
    private let platformKeywords = ["linux", "x86_64", "amd64", "x86-64", "aarch64", "arm64", "gnu"]
    private let platformExcludeKeywords = ["macos", "darwin", "osx", "apple", "windows", "win32", "win64"]
    private let archiveExtensions = [".zip", ".tar.gz", ".tgz"]
    #else
    private let platformKeywords = ["darwin", "macos", "mac", "osx", "x86_64", "amd64", "arm64", "universal", "artifactbundle"]
    private let platformExcludeKeywords = ["linux", "windows", "win32", "win64"]
    private let archiveExtensions = [".zip"]
    #endif
    
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
    
    func platformAsset(for release: Release) async throws -> ReleaseAsset {
        let releaseInfo = try await fetchReleaseInfo(release: release)
        return try findPlatformAsset(in: releaseInfo.assets)
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
    
    private func findPlatformAsset(in assets: [ReleaseAsset]) throws -> ReleaseAsset {
        let eligible = assets.filter { asset in
            let name = asset.name.lowercased()
            return !platformExcludeKeywords.contains { name.contains($0) }
        }
        
        let archiveAssets = eligible.filter { asset in
            let name = asset.name.lowercased()
            return archiveExtensions.contains { name.hasSuffix($0) }
        }
        if let asset = findBestMatch(in: archiveAssets) {
            return asset
        }
        
        let executableAssets = eligible.filter { URL(fileURLWithPath: $0.name).pathExtension.isEmpty }
        if let asset = findBestMatch(in: executableAssets) {
            return asset
        }

        throw ReleaseInfoProviderError.cannotIdentifyAsset(assets)
    }

    private func findBestMatch(in assets: [ReleaseAsset]) -> ReleaseAsset? {
        let sortedAssets = assets.sorted { asset1, asset2 in
            let count1 = platformKeywords.filter { asset1.name.lowercased().contains($0) }.count
            let count2 = platformKeywords.filter { asset2.name.lowercased().contains($0) }.count
            return count1 > count2
        }
        
        return sortedAssets.first { asset in
            platformKeywords.contains { keyword in
                asset.name.lowercased().contains(keyword)
            }
        }
    }
}
