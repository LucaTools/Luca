//  FileDownloading.swift

import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

/// Downloads a file from a URL and writes it to a temporary location on disk.
protocol FileDownloading {
    /// Downloads the resource at `url` and saves it to a temporary file.
    /// - Parameter url: The remote URL of the file to download.
    /// - Returns: A tuple of the temporary file URL and the URL response.
    func download(from url: URL) async throws -> (URL, URLResponse)
}
