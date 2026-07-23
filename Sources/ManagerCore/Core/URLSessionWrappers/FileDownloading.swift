//  FileDownloading.swift

import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

/// Downloads a file and writes it to a temporary location on disk.
protocol FileDownloading {
    /// Performs `request` and saves the response body to a temporary file.
    /// - Parameter request: The request to perform, with any headers (e.g. `Authorization`) already set.
    /// - Returns: A tuple of the temporary file URL and the URL response.
    func download(for request: URLRequest) async throws -> (URL, URLResponse)
}
