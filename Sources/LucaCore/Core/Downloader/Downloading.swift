//  Downloading.swift

import Foundation

protocol Downloading {
    func downloadRelease(at url: URL) async throws -> URL
}
