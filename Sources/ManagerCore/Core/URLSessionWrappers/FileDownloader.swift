//  FileDownloader.swift

import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

/// ``FileDownloading`` implementation backed by `URLSession`.
struct FileDownloader: FileDownloading {
    
    private var session: URLSession
    
    init(session: URLSession = .shared) {
        self.session = session
    }
    
    func download(from url: URL) async throws -> (URL, URLResponse) {
        try await session.download(from: url)
    }
}
