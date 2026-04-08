//  SkillSymLinkerFileManaging.swift

import Foundation

/// File system interface for ``SkillSymLinker``.
public protocol SkillSymLinkerFileManaging {
    var currentDirectoryPath: String { get }
    func fileExists(atPath: String) -> Bool
    func removeItem(at: URL) throws
    func createDirectory(at url: URL, withIntermediateDirectories: Bool) throws
    func createSymbolicLink(at url: URL, withDestinationURL destinationURL: URL) throws
    func attributesOfItem(atPath path: String) throws -> [FileAttributeKey: Any]
}
