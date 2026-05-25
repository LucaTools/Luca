//  FileDownloadingMock.swift

import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif
import Testing
@testable import LucaCore
@testable import ManagerCore

class FileDownloadingMock: FileDownloading {

    enum Result {
        case success(URL)
        case error(Error)
    }

    var result: Result

    init(result: Result) {
        self.result = result
    }

    func download(from url: URL) async throws -> (URL, URLResponse) {
        switch result {
        case .success(let tempURL):
            let response = HTTPURLResponse(url: url, statusCode: 200, httpVersion: nil, headerFields: nil)!
            return (tempURL, response)
        case .error(let error):
            throw error
        }
    }
}
