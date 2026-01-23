//  DownloaderMock.swift

import Foundation
import Testing
@testable import LucaCore

struct DownloaderMock: Downloading {
    
    enum Result {
        case fixture(Fixture)
        case error(Error)
    }
    
    var result: Result
    
    func downloadRelease(at url: URL) async throws -> URL {
        switch result {
        case .fixture(let fixture):
            let bundle = Bundle.module
            let path = try #require(bundle.path(forResource: fixture.filename, ofType: fixture.type))
            return URL(fileURLWithPath: path)
        case .error(let error):
            throw error
        }
    }
}
