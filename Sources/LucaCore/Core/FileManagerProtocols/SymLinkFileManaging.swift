//  SymLinkFileManaging.swift

import Foundation

/// File system interface for ``SymLinker``.
public protocol SymLinkFileManaging {
    var toolsFolder: URL { get }
    var activeFolder: URL { get }
    var homeDirectoryForCurrentUser: URL { get }
    var currentDirectoryPath: String { get }
    func fileExists(atPath: String) -> Bool
    func removeItem(at: URL) throws
    func createDirectory(at url: URL, withIntermediateDirectories: Bool) throws
    func createSymbolicLink(at url: URL, withDestinationURL destinationURL: URL) throws
    func attributesOfItem(atPath path: String) throws -> [FileAttributeKey: Any]
    func setAttributes(_ attributes: [FileAttributeKey : Any], ofItemAtPath path: String) throws
}
