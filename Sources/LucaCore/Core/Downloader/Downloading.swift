//  Downloading.swift

import Foundation

/// Downloads a release asset from a remote URL to a local temporary file.
protocol Downloading {
    /// Downloads a release asset to a temporary file.
    /// - Parameter url: The remote URL of the release archive or executable.
    /// - Returns: A URL pointing to the downloaded local file.
    func downloadRelease(at url: URL) async throws -> URL
}
