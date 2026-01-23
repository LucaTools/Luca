//  Downloading.swift

import Foundation

public protocol Downloading {
    func downloadRelease(at url: URL) async throws -> URL
}
