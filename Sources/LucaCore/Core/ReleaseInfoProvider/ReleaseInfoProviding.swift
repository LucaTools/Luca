//  ReleaseInfoProviding.swift

import Foundation

protocol ReleaseInfoProviding {
    /// Returns the most suitable release asset for the current platform.
    func platformAsset(for release: Release) async throws -> ReleaseAsset
}
