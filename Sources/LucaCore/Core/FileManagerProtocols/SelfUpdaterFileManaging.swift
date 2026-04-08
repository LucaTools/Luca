//  SelfUpdaterFileManaging.swift

import Foundation

/// File system interface for ``SelfUpdater``.
public protocol SelfUpdaterFileManaging {
    var currentDirectoryPath: String { get }
    var homeDirectoryForCurrentUser: URL { get }
    func fileExists(atPath path: String) -> Bool
    func contentsOfFile(atPath path: String) -> String?
    func isWritableFile(atPath path: String) -> Bool
    func createDirectory(at url: URL, withIntermediateDirectories: Bool) throws
    func removeItem(at url: URL) throws
    func moveItem(at srcURL: URL, to dstURL: URL) throws
    func writeString(_ content: String, to url: URL) throws
    func setAttributes(_ attributes: [FileAttributeKey: Any], ofItemAtPath path: String) throws
}
