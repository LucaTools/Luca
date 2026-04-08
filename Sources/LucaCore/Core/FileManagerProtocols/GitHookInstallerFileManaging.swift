//  GitHookInstallerFileManaging.swift

import Foundation

/// File system interface for ``GitHookInstaller``.
public protocol GitHookInstallerFileManaging {
    var currentDirectoryPath: String { get }
    var homeDirectoryForCurrentUser: URL { get }
    func fileExists(atPath: String) -> Bool
    func copyItem(at srcURL: URL, to dstURL: URL) throws
    func removeItem(at URL: URL) throws
    func readString(at url: URL) throws -> String
    func writeString(_ content: String, to url: URL) throws
    func setAttributes(_ attributes: [FileAttributeKey: Any], ofItemAtPath path: String) throws
    func attributesOfItem(atPath path: String) throws -> [FileAttributeKey: Any]
}
