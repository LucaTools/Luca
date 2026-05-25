//  DownloaderMock.swift

import Foundation
import Testing
@testable import LucaCore
@testable import ManagerCore

struct DownloaderMock: Downloading {
    
    enum Result {
        case fixture(Fixture)
        case tempFile(Data)
        case error(Error)
    }

    var result: Result

    func downloadRelease(at url: URL) async throws -> URL {
        switch result {
        case .fixture(let fixture):
            let bundle = Bundle.module
            let path = try #require(bundle.path(forResource: fixture.filename, ofType: fixture.type))
            return URL(fileURLWithPath: path)
        case .tempFile(let data):
            let tempURL = FileManager.default.temporaryDirectory
                .appending(component: "DownloaderMock-\(UUID().uuidString)")
            _ = FileManager.default.createFile(atPath: tempURL.path, contents: data)
            return tempURL
        case .error(let error):
            throw error
        }
    }
}
