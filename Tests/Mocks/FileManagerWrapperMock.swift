//  FileManagerWrapperMock.swift

import Foundation
@testable import LucaCore

class FileManagerWrapperMock: FileManaging {
    
    private(set) var fileManager: FileManager = .default
    
    private var _homeDirectoryForCurrentUser: URL?
    private var _currentDirectoryPath: String?

    var toolsFolder: URL {
        homeDirectoryForCurrentUser
            .appending(components: Constants.toolFolder, Constants.toolsFolder)
    }

    var symlinksFolder: URL {
        URL(fileURLWithPath: currentDirectoryPath)
            .appending(components: Constants.toolFolder, Constants.symlinksFolder)
    }
    
    init(fileManager: FileManager = .default) {
        self.fileManager = fileManager
    }
    
    var homeDirectoryForCurrentUser: URL {
        if let _homeDirectoryForCurrentUser {
            return _homeDirectoryForCurrentUser
        }
        let homeDirectoryForCurrentUser = fileManager.temporaryDirectory
            .appending(component: UUID().uuidString)
        _homeDirectoryForCurrentUser = homeDirectoryForCurrentUser
        return homeDirectoryForCurrentUser
    }

    var currentDirectoryPath: String {
        if let _currentDirectoryPath {
            return _currentDirectoryPath
        }
        let currentDirectoryPath = fileManager.temporaryDirectory
            .appending(component: UUID().uuidString)
            .path
        _currentDirectoryPath = currentDirectoryPath
        return currentDirectoryPath
    }
    
    func fileExists(atPath path: String) -> Bool {
        fileManager.fileExists(atPath: path)
    }
    
    func removeItem(at path: URL) throws {
        try fileManager.removeItem(at: path)
    }
    
    func removeItem(atPath path: String) throws {
        try fileManager.removeItem(atPath: path)
    }
    
    func moveItem(at: URL, to: URL) throws {
        try fileManager.moveItem(at: at, to: to)
    }
    
    func createDirectory(at url: URL, withIntermediateDirectories: Bool) throws {
        try fileManager.createDirectory(at: url, withIntermediateDirectories: withIntermediateDirectories)
    }
    
    func createSymbolicLink(at url: URL, withDestinationURL destinationURL: URL) throws {
        try fileManager.createSymbolicLink(at: url, withDestinationURL: destinationURL)
    }
    
    func destinationOfSymbolicLink(atPath path: String) throws -> String {
        try fileManager.destinationOfSymbolicLink(atPath: path)
    }
    
    func enumerator(at url: URL, includingPropertiesForKeys keys: [URLResourceKey]?, options mask: FileManager.DirectoryEnumerationOptions) -> FileManager.DirectoryEnumerator? {
        fileManager.enumerator(at: url, includingPropertiesForKeys: keys, options: mask)
    }
    
    func setAttributes(_ attributes: [FileAttributeKey: Any], ofItemAtPath path: String) throws {
        try fileManager.setAttributes(attributes, ofItemAtPath: path)
    }
    
    func contentsOfDirectory(at url: URL, includingPropertiesForKeys keys: [URLResourceKey]?, options mask: FileManager.DirectoryEnumerationOptions) throws -> [URL] {
        try fileManager.contentsOfDirectory(at: url, includingPropertiesForKeys: keys, options: mask)
    }
    
    func contents(atPath path: String) -> Data? {
        fileManager.contents(atPath: path)
    }
    
    func attributesOfItem(atPath path: String) throws -> [FileAttributeKey: Any] {
        try fileManager.attributesOfItem(atPath: path)
    }
    
    func copyItem(at srcURL: URL, to dstURL: URL) throws {
        try fileManager.copyItem(at: srcURL, to: dstURL)
    }
    
    func readString(at url: URL) throws -> String {
        try String(contentsOf: url, encoding: .utf8)
    }
    
    func writeString(_ content: String, to url: URL) throws {
        try content.write(to: url, atomically: true, encoding: .utf8)
    }
}
