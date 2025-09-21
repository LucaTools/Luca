//  ReleaseInfoProviding.swift

import Foundation

protocol ReleaseInfoProviding {
    func macOSAsset(for release: Release) async throws -> ReleaseAsset
}
