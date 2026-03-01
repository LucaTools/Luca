//  BinaryFinderFileManaging.swift

import Foundation

/// File system interface for ``BinaryFinder``.
public protocol BinaryFinderFileManaging {
    func enumerator(at url: URL, includingPropertiesForKeys keys: [URLResourceKey]?, options mask: FileManager.DirectoryEnumerationOptions) -> FileManager.DirectoryEnumerator?
}
