//  DataDownloading.swift

import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

protocol DataDownloading {
    func data(for request: URLRequest) async throws -> (Data, URLResponse)
}
