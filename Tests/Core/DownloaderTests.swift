//  DownloaderTests.swift

import Foundation
import Testing
@testable import LucaFoundation
@testable import ManagerCore

struct DownloaderTests {

    @Test
    func test_downloadRelease_zip_succeeds() async throws {
        let tempURL = FileManager.default.temporaryDirectory.appending(component: "tool.zip")
        let fileDownloader = FileDownloadingMock(result: .success(tempURL))
        let sut = Downloader(fileDownloader: fileDownloader)

        let url = try #require(URL(string: "https://example.com/releases/tool.zip"))
        let result = try await sut.downloadRelease(at: url)

        #expect(result == tempURL)
    }

    @Test
    func test_downloadRelease_targz_succeeds() async throws {
        let tempURL = FileManager.default.temporaryDirectory.appending(component: "tool.tar.gz")
        let fileDownloader = FileDownloadingMock(result: .success(tempURL))
        let sut = Downloader(fileDownloader: fileDownloader)

        let url = try #require(URL(string: "https://example.com/releases/tool.tar.gz"))
        let result = try await sut.downloadRelease(at: url)

        #expect(result == tempURL)
    }

    @Test
    func test_downloadRelease_tgz_succeeds() async throws {
        let tempURL = FileManager.default.temporaryDirectory.appending(component: "tool.tgz")
        let fileDownloader = FileDownloadingMock(result: .success(tempURL))
        let sut = Downloader(fileDownloader: fileDownloader)

        let url = try #require(URL(string: "https://example.com/releases/tool.tgz"))
        let result = try await sut.downloadRelease(at: url)

        #expect(result == tempURL)
    }

    @Test
    func test_downloadRelease_executable_noExtension_succeeds() async throws {
        let tempURL = FileManager.default.temporaryDirectory.appending(component: "tool-macOS")
        let fileDownloader = FileDownloadingMock(result: .success(tempURL))
        let sut = Downloader(fileDownloader: fileDownloader)

        let url = try #require(URL(string: "https://example.com/releases/tool-macOS"))
        let result = try await sut.downloadRelease(at: url)

        #expect(result == tempURL)
    }

    @Test
    func test_downloadRelease_executable_platformExtension_succeeds() async throws {
        let tempURL = FileManager.default.temporaryDirectory.appending(component: "tool.darwin")
        let fileDownloader = FileDownloadingMock(result: .success(tempURL))
        let sut = Downloader(fileDownloader: fileDownloader)

        let url = try #require(URL(string: "https://example.com/releases/tool.darwin"))
        let result = try await sut.downloadRelease(at: url)

        #expect(result == tempURL)
    }

    @Test
    func test_downloadRelease_downloaderError_propagates() async throws {
        struct DownloadError: Error {}
        let fileDownloader = FileDownloadingMock(result: .error(DownloadError()))
        let sut = Downloader(fileDownloader: fileDownloader)

        let url = try #require(URL(string: "https://example.com/releases/tool.zip"))

        await #expect(throws: (any Error).self) {
            _ = try await sut.downloadRelease(at: url)
        }
    }

    @Test
    func test_downloadRelease_attachesTokenForEnterpriseHost() async throws {
        let tempURL = FileManager.default.temporaryDirectory.appending(component: "tool.zip")
        let fileDownloader = FileDownloadingMock(result: .success(tempURL))
        let tokenResolver = GitHubTokenResolvingMock(tokensByHost: ["ghe.my-company.com": "ghe-token"])
        let sut = Downloader(fileDownloader: fileDownloader, tokenResolver: tokenResolver)

        let url = try #require(URL(string: "https://ghe.my-company.com/iOS/ModuleCreator/releases/download/2.5.0/ModuleCreator-macOS.zip"))
        _ = try await sut.downloadRelease(at: url)

        #expect(fileDownloader.lastRequest?.value(forHTTPHeaderField: "Authorization") == "Bearer ghe-token")
    }

    @Test
    func test_downloadRelease_omitsAuthorizationForGitHubDotCom() async throws {
        let tempURL = FileManager.default.temporaryDirectory.appending(component: "tool.zip")
        let fileDownloader = FileDownloadingMock(result: .success(tempURL))
        // Even if a token happens to be configured for github.com, it must never be attached
        // to the asset-download request: github.com redirects release-asset downloads to
        // objects.githubusercontent.com with a presigned URL, and forwarding our token there
        // would leak it to a third-party host.
        let tokenResolver = GitHubTokenResolvingMock(tokensByHost: ["github.com": "dotcom-token"])
        let sut = Downloader(fileDownloader: fileDownloader, tokenResolver: tokenResolver)

        let url = try #require(URL(string: "https://github.com/realm/SwiftLint/releases/download/0.61.0/SwiftLintBinary.artifactbundle.zip"))
        _ = try await sut.downloadRelease(at: url)

        #expect(fileDownloader.lastRequest?.value(forHTTPHeaderField: "Authorization") == nil)
    }

    @Test
    func test_downloadRelease_omitsAuthorizationWhenNoTokenConfigured() async throws {
        let tempURL = FileManager.default.temporaryDirectory.appending(component: "tool.zip")
        let fileDownloader = FileDownloadingMock(result: .success(tempURL))
        let tokenResolver = GitHubTokenResolvingMock(tokensByHost: [:])
        let sut = Downloader(fileDownloader: fileDownloader, tokenResolver: tokenResolver)

        let url = try #require(URL(string: "https://ghe.my-company.com/iOS/ModuleCreator/releases/download/2.5.0/ModuleCreator-macOS.zip"))
        _ = try await sut.downloadRelease(at: url)

        #expect(fileDownloader.lastRequest?.value(forHTTPHeaderField: "Authorization") == nil)
    }

    @Test
    func test_downloadRelease_setsOctetStreamAcceptHeader() async throws {
        let tempURL = FileManager.default.temporaryDirectory.appending(component: "tool.zip")
        let fileDownloader = FileDownloadingMock(result: .success(tempURL))
        let sut = Downloader(fileDownloader: fileDownloader, tokenResolver: GitHubTokenResolvingMock(tokensByHost: [:]))

        let url = try #require(URL(string: "https://ghe.my-company.com/api/v3/repos/iOS/ModuleCreator/releases/assets/12345"))
        _ = try await sut.downloadRelease(at: url)

        #expect(fileDownloader.lastRequest?.value(forHTTPHeaderField: "Accept") == "application/octet-stream")
    }
}
