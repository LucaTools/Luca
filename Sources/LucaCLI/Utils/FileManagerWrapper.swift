//  FileManagerWrapper.swift

import Foundation
import LucaCore

public struct FileManagerWrapper: FileManaging {
    
    private(set) var fileManager: FileManager
    
    init(fileManager: FileManager = .default) {
        self.fileManager = fileManager
    }
    
    /// Root folder for all installed versions.
    public var toolsFolder: URL {
        homeDirectoryForCurrentUser
            .appending(components: Constants.toolFolder, Constants.toolsFolder)
    }

    /// Folder containing symlinks to currently active binaries (per working directory).
    public var symlinksFolder: URL {
        URL(fileURLWithPath: currentDirectoryPath)
            .appending(components: Constants.toolFolder, Constants.symlinksFolder)
    }

    /// Folder containing project-local skills cache (per working directory).
    public var skillsCacheFolder: URL {
        URL(fileURLWithPath: currentDirectoryPath)
            .appending(components: Constants.toolFolder, Constants.skillsFolder)
    }
    
    public var homeDirectoryForCurrentUser: URL {
        fileManager.homeDirectoryForCurrentUser
    }

    public var currentDirectoryPath: String {
        fileManager.currentDirectoryPath
    }
    
    public func fileExists(atPath path: String) -> Bool {
        fileManager.fileExists(atPath: path)
    }

    @discardableResult
    public func createFile(atPath path: String, contents data: Data?) -> Bool {
        fileManager.createFile(atPath: path, contents: data)
    }

    public func removeItem(at path: URL) throws {
        try fileManager.removeItem(at: path)
    }
    
    public func removeItem(atPath path: String) throws {
        try fileManager.removeItem(atPath: path)
    }
    
    public func moveItem(at: URL, to: URL) throws {
        try fileManager.moveItem(at: at, to: to)
    }
    
    public func createDirectory(at url: URL, withIntermediateDirectories: Bool) throws {
        try fileManager.createDirectory(at: url, withIntermediateDirectories: withIntermediateDirectories)
    }
    
    public func createSymbolicLink(at url: URL, withDestinationURL destinationURL: URL) throws {
        try fileManager.createSymbolicLink(at: url, withDestinationURL: destinationURL)
    }
    
    public func destinationOfSymbolicLink(atPath path: String) throws -> String {
        try fileManager.destinationOfSymbolicLink(atPath: path)
    }
    
    public func enumerator(at url: URL, includingPropertiesForKeys keys: [URLResourceKey]?, options mask: FileManager.DirectoryEnumerationOptions) -> FileManager.DirectoryEnumerator? {
        fileManager.enumerator(at: url, includingPropertiesForKeys: keys, options: mask)
    }
    
    public func setAttributes(_ attributes: [FileAttributeKey: Any], ofItemAtPath path: String) throws {
        try fileManager.setAttributes(attributes, ofItemAtPath: path)
    }
    
    public func contentsOfDirectory(at url: URL, includingPropertiesForKeys keys: [URLResourceKey]?, options mask: FileManager.DirectoryEnumerationOptions) throws -> [URL] {
        try fileManager.contentsOfDirectory(at: url, includingPropertiesForKeys: keys, options: mask)
    }
    
    public func contents(atPath path: String) -> Data? {
        fileManager.contents(atPath: path)
    }
    
    public func attributesOfItem(atPath path: String) throws -> [FileAttributeKey: Any] {
        try fileManager.attributesOfItem(atPath: path)
    }
    
    public func copyItem(at srcURL: URL, to dstURL: URL) throws {
        try fileManager.copyItem(at: srcURL, to: dstURL)
    }

    public func contentsOfFile(atPath path: String) -> String? {
        guard let data = fileManager.contents(atPath: path) else { return nil }
        return String(data: data, encoding: .utf8)
    }

    public func isWritableFile(atPath path: String) -> Bool {
        fileManager.isWritableFile(atPath: path)
    }
    
    public func readString(at url: URL) throws -> String {
        try String(contentsOf: url, encoding: .utf8)
    }
    
    public func writeString(_ content: String, to url: URL) throws {
        try content.write(to: url, atomically: true, encoding: .utf8)
    }
}
