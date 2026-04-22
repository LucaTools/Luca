//  InstalledSkillsListerFileManaging.swift

import Foundation

/// File system interface for ``InstalledSkillsLister``.
public protocol InstalledSkillsListerFileManaging {
    var skillsCacheFolder: URL { get }
    var globalSkillsCacheFolder: URL { get }
    func fileExists(atPath: String) -> Bool
    func contentsOfDirectory(at url: URL, includingPropertiesForKeys keys: [URLResourceKey]?, options mask: FileManager.DirectoryEnumerationOptions) throws -> [URL]
    func attributesOfItem(atPath path: String) throws -> [FileAttributeKey: Any]
}
