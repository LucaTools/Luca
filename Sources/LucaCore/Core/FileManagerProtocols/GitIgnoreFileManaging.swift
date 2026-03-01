//  GitIgnoreFileManaging.swift

import Foundation

/// File system interface for ``GitIgnoreManager``.
public protocol GitIgnoreFileManaging {
    var currentDirectoryPath: String { get }
    func fileExists(atPath: String) -> Bool
    func readString(at url: URL) throws -> String
    func writeString(_ content: String, to url: URL) throws
}
