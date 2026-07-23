//  FileDownloaderTests.swift

import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif
import Testing
@testable import LucaFoundation
@testable import ManagerCore

// URLSession.download(from:) on Linux's FoundationNetworking does not support URLProtocol
// interception: urlProtocolDidFinishLoading crashes because no real temp file is ever written.
// These tests are macOS-only; FileDownloader is covered via integration paths on Linux.
#if canImport(Darwin)
@Suite(.serialized)
struct FileDownloaderTests {

    @Test
    func test_download_success() async throws {
        MockFileURLProtocol.requestHandler = { request in
            let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
            return (response, Data("file contents".utf8))
        }
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [MockFileURLProtocol.self]
        let sut = FileDownloader(session: URLSession(configuration: config))

        let url = try #require(URL(string: "https://example.com/tool.zip"))
        let (downloadedURL, response) = try await sut.download(for: URLRequest(url: url))

        #expect(downloadedURL.isFileURL)
        let httpResponse = try #require(response as? HTTPURLResponse)
        #expect(httpResponse.statusCode == 200)
    }

    @Test
    func test_download_errorPropagates() async throws {
        MockFileURLProtocol.requestHandler = { _ in throw URLError(.notConnectedToInternet) }
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [MockFileURLProtocol.self]
        let sut = FileDownloader(session: URLSession(configuration: config))

        let url = try #require(URL(string: "https://example.com/tool.zip"))
        await #expect(throws: (any Error).self) {
            _ = try await sut.download(for: URLRequest(url: url))
        }
    }

    @Test
    func test_download_forwardsRequestHeaders() async throws {
        var capturedRequest: URLRequest?
        MockFileURLProtocol.requestHandler = { request in
            capturedRequest = request
            let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
            return (response, Data("file contents".utf8))
        }
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [MockFileURLProtocol.self]
        let sut = FileDownloader(session: URLSession(configuration: config))

        let url = try #require(URL(string: "https://example.com/tool.zip"))
        var request = URLRequest(url: url)
        request.setValue("Bearer test-token-value", forHTTPHeaderField: "Authorization")
        _ = try await sut.download(for: request)

        #expect(capturedRequest?.value(forHTTPHeaderField: "Authorization") == "Bearer test-token-value")
    }
}

// MARK: - Private Mocks

private final class MockFileURLProtocol: URLProtocol {
    nonisolated(unsafe) static var requestHandler: ((URLRequest) throws -> (HTTPURLResponse, Data))?

    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

    override func startLoading() {
        guard let handler = MockFileURLProtocol.requestHandler else {
            client?.urlProtocol(self, didFailWithError: URLError(.unknown))
            return
        }
        do {
            let (response, data) = try handler(request)
            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            client?.urlProtocol(self, didLoad: data)
            client?.urlProtocolDidFinishLoading(self)
        } catch {
            client?.urlProtocol(self, didFailWithError: error)
        }
    }

    override func stopLoading() {}
}
#endif
