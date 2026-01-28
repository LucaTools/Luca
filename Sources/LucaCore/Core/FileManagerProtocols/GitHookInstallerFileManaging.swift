//  GitHookInstallerFileManaging.swift

import Foundation

public protocol GitHookInstallerFileManaging {
    var currentDirectoryPath: String { get }
    var homeDirectoryForCurrentUser: URL { get }
    func fileExists(atPath: String) -> Bool
    func copyItem(at srcURL: URL, to dstURL: URL) throws
    func setAttributes(_ attributes: [FileAttributeKey: Any], ofItemAtPath path: String) throws
}
