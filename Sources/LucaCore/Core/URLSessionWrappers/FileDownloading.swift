//  FileDownloading.swift

import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

protocol FileDownloading {
    func download(from url: URL) async throws -> (URL, URLResponse)
}
