//  ReleaseInfoProviderTests.swift

import Testing
@testable import LucaCore
@testable import ManagerCore

struct ReleaseInfoProviderTests {

    @Test
    func fetchReleaseInfo_success() async throws {
        let dataDownloader = DataDownloaderMock(result: .fixture(Fixture(filename: "ReleaseInfo", type: "json")))
        let sut = ReleaseInfoProvider(dataDownloader: dataDownloader)
        let release = Release(organization: "organization", repository: "repository", version: "1.0.0")
        let asset = try await sut.platformAsset(for: release)
        #if os(Linux)
        let targetAsset = ReleaseAsset(name: "tool-Linux.zip", url: "https://github.com/organization/repository/releases/download/1.0.0/tool-Linux.zip")
        #else
        let targetAsset = ReleaseAsset(name: "tool-macOS.zip", url: "https://github.com/organization/repository/releases/download/1.0.0/tool-macOS.zip")
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
        let release = Release(organization: "organization", repository: "repository", version: "1.0.0")
        let asset = try await sut.platformAsset(for: release)
        #if os(Linux)
        let targetAsset = ReleaseAsset(name: "tool-Linux", url: "https://github.com/organization/repository/releases/download/1.0.0/tool-Linux")
        #else
        let targetAsset = ReleaseAsset(name: "tool-macOS", url: "https://github.com/organization/repository/releases/download/1.0.0/tool-macOS")
        #endif
        #expect(asset == targetAsset)
    }

    @Test
    func fetchReleaseInfo_mixedAssets_preferArchive() async throws {
        #if os(Linux)
        let dataDownloader = DataDownloaderMock(result: .fixture(Fixture(filename: "MixedLinuxAssets", type: "json")))
        let targetAsset = ReleaseAsset(name: "tool-linux.tar.gz", url: "https://github.com/organization/repository/releases/download/1.0.0/tool-linux.tar.gz")
        #else
        let dataDownloader = DataDownloaderMock(result: .fixture(Fixture(filename: "MixedAssets", type: "json")))
        let targetAsset = ReleaseAsset(name: "tool-macOS.zip", url: "https://github.com/organization/repository/releases/download/1.0.0/tool-macOS.zip")
        #endif
        let sut = ReleaseInfoProvider(dataDownloader: dataDownloader)
        let release = Release(organization: "organization", repository: "repository", version: "1.0.0")
        let asset = try await sut.platformAsset(for: release)
        #expect(asset == targetAsset)
    }

    @Test
    func fetchReleaseInfo_multipleMatchingAssets_prefersBestMatch() async throws {
        let dataDownloader = DataDownloaderMock(result: .fixture(Fixture(filename: "MultipleMatchingAssets", type: "json")))
        let sut = ReleaseInfoProvider(dataDownloader: dataDownloader)
        let release = Release(organization: "organization", repository: "repository", version: "1.0.0")
        let asset = try await sut.platformAsset(for: release)
        #if os(Linux)
        let targetAsset = ReleaseAsset(name: "tool-linux-gnu.tar.gz", url: "https://github.com/organization/repository/releases/download/1.0.0/tool-linux-gnu.tar.gz")
        #else
        let targetAsset = ReleaseAsset(name: "tool-macOS-arm64.zip", url: "https://github.com/organization/repository/releases/download/1.0.0/tool-macOS-arm64.zip")
        #endif
        #expect(asset == targetAsset)
    }

    @Test
    func fetchReleaseInfo_nonHTTPResponse_throwsApiError() async throws {
        let dataDownloader = DataDownloaderMock(result: .nonHTTPResponse)
        let sut = ReleaseInfoProvider(dataDownloader: dataDownloader)
        let release = Release(organization: "organization", repository: "repository", version: "1.0.0")
        await #expect(throws: ReleaseInfoProvider.ReleaseInfoProviderError.apiError("Invalid response from GitHub")) {
            try await sut.platformAsset(for: release)
        }
    }

    @Test
    func fetchReleaseInfo_serverError_throwsApiError() async throws {
        let dataDownloader = DataDownloaderMock(result: .statusCode(500))
        let sut = ReleaseInfoProvider(dataDownloader: dataDownloader)
        let release = Release(organization: "organization", repository: "repository", version: "1.0.0")
        await #expect(throws: ReleaseInfoProvider.ReleaseInfoProviderError.apiError("HTTP error 500")) {
            try await sut.platformAsset(for: release)
        }
    }
}
