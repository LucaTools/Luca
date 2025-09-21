//  ReleaseInfoProviderTests.swift

import Testing
@testable import LucaCore

struct ReleaseInfoProviderTests {
    
    @Test
    func fetchReleaseInfo_success() async throws {
        let dataDownloader = DataDownloaderMock(result: .fixture(Fixture(filename: "ToggleGenReleaseInfo", type: "json")))
        let sut = ReleaseInfoProvider(dataDownloader: dataDownloader)
        let release = Release(organization: "TogglesPlatform", repository: "ToggleGen", version: "1.0.0")
        let asset = try await sut.macOSAsset(for: release)
        let targetAsset = ReleaseAsset(name: "ToggleGen-macOS.zip", url: "https://github.com/TogglesPlatform/ToggleGen/releases/download/1.0.0/ToggleGen-macOS.zip")
        #expect(asset == targetAsset)
    }
    
    @Test
    func fetchReleaseInfo_missingMacOSAsset() async throws {
        let dataDownloader = DataDownloaderMock(result: .fixture(Fixture(filename: "MissingMacOSAsset", type: "json")))
        let sut = ReleaseInfoProvider(dataDownloader: dataDownloader)
        let release = Release(organization: "organization", repository: "repository", version: "1.0.0")
        let assets = [
            ReleaseAsset(name: "Linux-release.zip", url: "https://github.com/organization/repository/releases/download/1.0.0/Linux-release.zip"),
            ReleaseAsset(name: "Windows-release.zip", url: "https://github.com/organization/repository/releases/download/1.0.0/Windows-release.zip")
        ]
        await #expect(throws: ReleaseInfoProvider.ReleaseInfoProviderError.cannotIdentifyAsset(assets)) {
            try await sut.macOSAsset(for: release)
        }
    }
    
    @Test
    func fetchReleaseInfo_missingRelease() async throws {
        let dataDownloader = DataDownloaderMock(result: .statusCode(404))
        let sut = ReleaseInfoProvider(dataDownloader: dataDownloader)
        let release = Release(organization: "organization", repository: "repository", version: "1.0.0")
        let releaseUrl = try GitHubReleaseURLFactory().makeApiReleaseURL(release: release)
        await #expect(throws: ReleaseInfoProvider.ReleaseInfoProviderError.releaseNotFound(releaseUrl)) {
            try await sut.macOSAsset(for: release)
        }
    }
}
