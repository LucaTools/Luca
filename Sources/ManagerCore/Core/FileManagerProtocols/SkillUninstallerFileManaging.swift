//  SkillUninstallerFileManaging.swift

import Foundation

/// File system interface for ``SkillUninstaller``.
public protocol SkillUninstallerFileManaging {
    var skillsCacheFolder: URL { get }
    var globalSkillsCacheFolder: URL { get }
    var homeDirectoryForCurrentUser: URL { get }
    var currentDirectoryPath: String { get }
    func fileExists(atPath: String) -> Bool
    func removeItem(at url: URL) throws
    func removeItem(atPath path: String) throws
}
