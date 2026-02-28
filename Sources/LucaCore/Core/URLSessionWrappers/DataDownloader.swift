//  DataDownloader.swift

import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

struct DataDownloader: DataDownloading {
    
    private var session: URLSession
    
    init(session: URLSession = .shared) {
        self.session = session
    }
    
    func data(for request: URLRequest) async throws -> (Data, URLResponse) {
        try await session.data(for: request)
    }
}
