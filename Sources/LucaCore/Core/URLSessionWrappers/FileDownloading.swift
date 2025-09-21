//  FileDownloading.swift

import Foundation

protocol FileDownloading {
    func download(from url: URL) async throws -> (URL, URLResponse)
}
