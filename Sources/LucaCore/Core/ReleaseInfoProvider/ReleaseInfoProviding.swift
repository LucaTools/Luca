//  ReleaseInfoProviding.swift

import Foundation

/// Retrieves GitHub release metadata and identifies the best asset for the current platform.
protocol ReleaseInfoProviding {
    /// Returns the most suitable release asset for the current platform.
    func platformAsset(for release: Release) async throws -> ReleaseAsset
}
