//  InstalledToolsFileManaging.swift

import Foundation

/// File system interface for ``InstalledToolsLister``.
public protocol InstalledToolsFileManaging {
    var toolsFolder: URL { get }
    func fileExists(atPath: String) -> Bool
    func contentsOfDirectory(at url: URL, includingPropertiesForKeys keys: [URLResourceKey]?, options mask: FileManager.DirectoryEnumerationOptions) throws -> [URL]
    func attributesOfItem(atPath path: String) throws -> [FileAttributeKey: Any]
}
