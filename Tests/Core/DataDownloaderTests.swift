//  DataDownloaderTests.swift

import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif
import Testing
@testable import LucaFoundation
@testable import ManagerCore

@Suite(.serialized)
struct DataDownloaderTests {

    @Test
    func test_data_success() async throws {
        MockDataURLProtocol.requestHandler = { request in
            let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
            return (response, Data("response body".utf8))
        }
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [MockDataURLProtocol.self]
        let sut = DataDownloader(session: URLSession(configuration: config))

        let url = try #require(URL(string: "https://example.com/api"))
        let (data, response) = try await sut.data(for: URLRequest(url: url))

        #expect(data == Data("response body".utf8))
        let httpResponse = try #require(response as? HTTPURLResponse)
        #expect(httpResponse.statusCode == 200)
    }

    @Test
    func test_data_errorPropagates() async throws {
        MockDataURLProtocol.requestHandler = { _ in throw URLError(.notConnectedToInternet) }
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [MockDataURLProtocol.self]
        let sut = DataDownloader(session: URLSession(configuration: config))

        let url = try #require(URL(string: "https://example.com/api"))
        await #expect(throws: (any Error).self) {
            _ = try await sut.data(for: URLRequest(url: url))
        }
    }
}

// MARK: - Private Mocks

private final class MockDataURLProtocol: URLProtocol {
    nonisolated(unsafe) static var requestHandler: ((URLRequest) throws -> (HTTPURLResponse, Data))?

    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

    override func startLoading() {
        guard let handler = MockDataURLProtocol.requestHandler else {
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
