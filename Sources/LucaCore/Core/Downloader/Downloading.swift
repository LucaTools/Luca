//  Downloading.swift

import Foundation

protocol Downloading {
    func downloadArchive(at url: URL) async throws -> URL
}
