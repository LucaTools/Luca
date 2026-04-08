//  FileManaging.swift

import Foundation

/// The full file-system interface used by components that require access to multiple file manager capabilities.
public protocol FileManaging:
    ArchitectureValidatorFileManaging,
    BinaryFinderFileManaging,
    ChecksumValidatorFileManaging,
    FileTypeDetectorFileManaging,
    GitHookInstallerFileManaging,
    GitIgnoreFileManaging,
    InstalledSkillsListerFileManaging,
    InstalledToolsFileManaging,
    PermissionManagerFileManaging,
    SelfUpdaterFileManaging,
    SkillSymLinkerFileManaging,
    SkillUninstallerFileManaging,
    SpecFinderFileManaging,
    SymLinkFileManaging,
    UnarchiverFileManaging {
    var toolsFolder: URL { get }
    var symlinksFolder: URL { get }
    var skillsCacheFolder: URL { get }
    var homeDirectoryForCurrentUser: URL { get }
    var currentDirectoryPath: String { get }
    func fileExists(atPath: String) -> Bool
    @discardableResult func createFile(atPath path: String, contents data: Data?) -> Bool
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
    func copyItem(at srcURL: URL, to dstURL: URL) throws
}
