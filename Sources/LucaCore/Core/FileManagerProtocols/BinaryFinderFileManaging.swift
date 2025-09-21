//  BinaryFinderFileManaging.swift

import Foundation

public protocol BinaryFinderFileManaging {
    func enumerator(at url: URL, includingPropertiesForKeys keys: [URLResourceKey]?, options mask: FileManager.DirectoryEnumerationOptions) -> FileManager.DirectoryEnumerator?
}
