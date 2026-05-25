//  DataDownloading.swift

import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

/// Fetches response data for a URL request, used for GitHub API calls.
protocol DataDownloading {
    /// Performs the URL request and returns the response body and metadata.
    /// - Parameter request: The URL request to execute.
    /// - Returns: A tuple of the response data and URL response.
    func data(for request: URLRequest) async throws -> (Data, URLResponse)
}
