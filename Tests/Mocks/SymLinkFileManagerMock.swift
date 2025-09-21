//  SymLinkFileManagerMock.swift

import Foundation
@testable import LucaCore

class SymLinkFileManagerMock: SymLinkFileManaging {
    
    private(set) var fileManager: FileManager
    
    private var _homeDirectoryForCurrentUser: URL?
    private var _currentDirectoryPath: String?

    var toolsFolder: URL {
        homeDirectoryForCurrentUser
            .appending(components: Constants.toolFolder, Constants.toolsFolder)
    }

    var activeFolder: URL {
        URL(fileURLWithPath: currentDirectoryPath)
            .appending(components: Constants.toolFolder, Constants.activeFolder)
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
    
    func removeItem(at path: URL) throws {
        try fileManager.removeItem(at: path)
    }
    
    func fileExists(atPath path: String) -> Bool {
        fileManager.fileExists(atPath: path)
    }
    
    func createDirectory(at url: URL, withIntermediateDirectories: Bool) throws {
        try fileManager.createDirectory(at: url, withIntermediateDirectories: withIntermediateDirectories)
    }
    
    func createSymbolicLink(at url: URL, withDestinationURL destinationURL: URL) throws {
        try fileManager.createSymbolicLink(at: url, withDestinationURL: destinationURL)
    }
    
    func attributesOfItem(atPath path: String) throws -> [FileAttributeKey: Any] {
        try fileManager.attributesOfItem(atPath: path)
    }
    
    func setAttributes(_ attributes: [FileAttributeKey : Any], ofItemAtPath path: String) throws {
        try fileManager.setAttributes(attributes, ofItemAtPath: path)
    }
}
