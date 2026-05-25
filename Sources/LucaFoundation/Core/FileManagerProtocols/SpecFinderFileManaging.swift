//  SpecFinderFileManaging.swift

import Foundation

/// File system interface for ``SpecFinder``.
public protocol SpecFinderFileManaging {
    var currentDirectoryPath: String { get }
    func fileExists(atPath: String) -> Bool
    func contentsOfDirectory(at url: URL, includingPropertiesForKeys keys: [URLResourceKey]?, options mask: FileManager.DirectoryEnumerationOptions) throws -> [URL]
}
