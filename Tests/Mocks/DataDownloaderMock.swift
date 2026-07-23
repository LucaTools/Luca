//  DataDownloaderMock.swift

import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif
import Testing
@testable import LucaFoundation
@testable import ManagerCore

struct DataDownloaderMock: DataDownloading {
    
    enum Result {
        case fixture(Fixture)
        case statusCode(Int)
        case rawData(Data, Int)
        case nonHTTPResponse
        case error(any Error)
    }

    var result: Result
    var onRequest: (@Sendable (URLRequest) -> Void)? = nil

    func data(for request: URLRequest) async throws -> (Data, URLResponse) {
        onRequest?(request)
        switch result {
        case .fixture(let fixture):
            let bundle = Bundle.module
            let path = try #require(bundle.path(forResource: fixture.filename, ofType: fixture.type))
            let data = try #require(FileManager.default.contents(atPath: path))
            let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
            return (data, response)
        case .statusCode(let statusCode):
            let data = Data()
            let response = HTTPURLResponse(url: request.url!, statusCode: statusCode, httpVersion: nil, headerFields: nil)!
            return (data, response)
        case .rawData(let data, let statusCode):
            let response = HTTPURLResponse(url: request.url!, statusCode: statusCode, httpVersion: nil, headerFields: nil)!
            return (data, response)
        case .nonHTTPResponse:
            let response = URLResponse(url: request.url!, mimeType: nil, expectedContentLength: 0, textEncodingName: nil)
            return (Data(), response)
        case .error(let error):
            throw error
        }
    }
}
