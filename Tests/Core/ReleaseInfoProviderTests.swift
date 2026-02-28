//  ReleaseInfoProviderTests.swift

import Testing
@testable import LucaCore

struct ReleaseInfoProviderTests {
    
    @Test
    func fetchReleaseInfo_success() async throws {
        let dataDownloader = DataDownloaderMock(result: .fixture(Fixture(filename: "ToggleGenReleaseInfo", type: "json")))
        let sut = ReleaseInfoProvider(dataDownloader: dataDownloader)
        let release = Release(organization: "TogglesPlatform", repository: "ToggleGen", version: "1.0.0")
        let asset = try await sut.platformAsset(for: release)
        #if os(Linux)
        let targetAsset = ReleaseAsset(name: "ToggleGen-Linux.zip", url: "https://github.com/TogglesPlatform/ToggleGen/releases/download/1.0.0/ToggleGen-Linux.zip")
        #else
        let targetAsset = ReleaseAsset(name: "ToggleGen-macOS.zip", url: "https://github.com/TogglesPlatform/ToggleGen/releases/download/1.0.0/ToggleGen-macOS.zip")
        #endif
        #expect(asset == targetAsset)
    }
    
    @Test
    func fetchReleaseInfo_missingPlatformAsset() async throws {
        #if os(Linux)
        let dataDownloader = DataDownloaderMock(result: .fixture(Fixture(filename: "MissingLinuxAsset", type: "json")))
        let assets = [
            ReleaseAsset(name: "macOS-release.zip", url: "https://github.com/organization/repository/releases/download/1.0.0/macOS-release.zip"),
            ReleaseAsset(name: "Windows-release.zip", url: "https://github.com/organization/repository/releases/download/1.0.0/Windows-release.zip")
        ]
        #else
        let dataDownloader = DataDownloaderMock(result: .fixture(Fixture(filename: "MissingMacOSAsset", type: "json")))
        let assets = [
            ReleaseAsset(name: "Linux-release.zip", url: "https://github.com/organization/repository/releases/download/1.0.0/Linux-release.zip"),
            ReleaseAsset(name: "Windows-release.zip", url: "https://github.com/organization/repository/releases/download/1.0.0/Windows-release.zip")
        ]
        #endif
        let sut = ReleaseInfoProvider(dataDownloader: dataDownloader)
        let release = Release(organization: "organization", repository: "repository", version: "1.0.0")
        await #expect(throws: ReleaseInfoProvider.ReleaseInfoProviderError.cannotIdentifyAsset(assets)) {
            try await sut.platformAsset(for: release)
        }
    }
    
    @Test
    func fetchReleaseInfo_missingRelease() async throws {
        let dataDownloader = DataDownloaderMock(result: .statusCode(404))
        let sut = ReleaseInfoProvider(dataDownloader: dataDownloader)
        let release = Release(organization: "organization", repository: "repository", version: "1.0.0")
        let releaseUrl = try GitHubReleaseURLFactory().makeApiReleaseURL(release: release)
        await #expect(throws: ReleaseInfoProvider.ReleaseInfoProviderError.releaseNotFound(releaseUrl)) {
            try await sut.platformAsset(for: release)
        }
    }

    @Test
    func fetchReleaseInfo_executableAsset() async throws {
        let dataDownloader = DataDownloaderMock(result: .fixture(Fixture(filename: "ExecutableAssets", type: "json")))
        let sut = ReleaseInfoProvider(dataDownloader: dataDownloader)
        let release = Release(organization: "TogglesPlatform", repository: "ToggleGen", version: "1.0.0")
        let asset = try await sut.platformAsset(for: release)
        #if os(Linux)
        let targetAsset = ReleaseAsset(name: "ToggleGen-Linux", url: "https://github.com/TogglesPlatform/ToggleGen/releases/download/1.0.0/ToggleGen-Linux")
        #else
        let targetAsset = ReleaseAsset(name: "ToggleGen-macOS", url: "https://github.com/TogglesPlatform/ToggleGen/releases/download/1.0.0/ToggleGen-macOS")
        #endif
        #expect(asset == targetAsset)
    }
    
    @Test
    func fetchReleaseInfo_mixedAssets_preferArchive() async throws {
        #if os(Linux)
        let dataDownloader = DataDownloaderMock(result: .fixture(Fixture(filename: "MixedLinuxAssets", type: "json")))
        let targetAsset = ReleaseAsset(name: "ToggleGen-linux.tar.gz", url: "https://github.com/TogglesPlatform/ToggleGen/releases/download/1.0.0/ToggleGen-linux.tar.gz")
        #else
        let dataDownloader = DataDownloaderMock(result: .fixture(Fixture(filename: "MixedAssets", type: "json")))
        let targetAsset = ReleaseAsset(name: "ToggleGen-macOS.zip", url: "https://github.com/TogglesPlatform/ToggleGen/releases/download/1.0.0/ToggleGen-macOS.zip")
        #endif
        let sut = ReleaseInfoProvider(dataDownloader: dataDownloader)
        let release = Release(organization: "TogglesPlatform", repository: "ToggleGen", version: "1.0.0")
        let asset = try await sut.platformAsset(for: release)
        #expect(asset == targetAsset)
    }
}
