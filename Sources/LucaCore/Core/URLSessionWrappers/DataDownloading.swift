//  DataDownloading.swift

import Foundation

protocol DataDownloading {
    func data(for request: URLRequest) async throws -> (Data, URLResponse)
}
