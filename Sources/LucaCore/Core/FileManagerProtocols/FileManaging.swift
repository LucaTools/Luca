//  FileManaging.swift

import Foundation

public protocol FileManaging:
    BinaryFinderFileManaging,
    ChecksumValidatorFileManaging,
    FileTypeDetectorFileManaging,
    PermissionManagerFileManaging,
    SymLinkFileManaging,
    UnarchiverFileManaging {
    var toolsFolder: URL { get }
    var activeFolder: URL { get }
    var homeDirectoryForCurrentUser: URL { get }
    var currentDirectoryPath: String { get }
    func fileExists(atPath: String) -> Bool
    func removeItem(at: URL) throws
    func removeItem(atPath: String) throws
    func moveItem(at: URL, to: URL) throws
    func createDirectory(at url: URL, withIntermediateDirectories: Bool) throws
    func createSymbolicLink(at url: URL, withDestinationURL destinationURL: URL) throws
    func destinationOfSymbolicLink(atPath path: String) throws -> String
    func enumerator(at url: URL, includingPropertiesForKeys keys: [URLResourceKey]?, options mask: FileManager.DirectoryEnumerationOptions) -> FileManager.DirectoryEnumerator?
    func setAttributes(_ attributes: [FileAttributeKey: Any], ofItemAtPath path: String) throws
    func contentsOfDirectory(at url: URL, includingPropertiesForKeys keys: [URLResourceKey]?, options mask: FileManager.DirectoryEnumerationOptions) throws -> [URL]
    func attributesOfItem(atPath path: String) throws -> [FileAttributeKey: Any]
}
