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
}
