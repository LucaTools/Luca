//  DataDownloaderMock.swift

import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif
import Testing
@testable import LucaCore

struct DataDownloaderMock: DataDownloading {
    
    enum Result {
        case fixture(Fixture)
        case statusCode(Int)
    }
    
    var result: Result
    
    func data(for request: URLRequest) async throws -> (Data, URLResponse) {
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
        }
    }
}
