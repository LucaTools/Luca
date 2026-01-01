//  InstalledToolsFileManagerMock.swift

import Foundation
@testable import LucaCore

class InstalledToolsFileManagerMock: InstalledToolsFileManaging {
    
    private(set) var fileManager: FileManager = .default
    
    private var _homeDirectoryForCurrentUser: URL?
    private var _currentDirectoryPath: String?

    var toolsFolder: URL {
        homeDirectoryForCurrentUser
            .appending(components: Constants.toolFolder, Constants.toolsFolder)
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
    
    func fileExists(atPath path: String) -> Bool {
        fileManager.fileExists(atPath: path)
    }
    
    func contentsOfDirectory(at url: URL, includingPropertiesForKeys keys: [URLResourceKey]?, options mask: FileManager.DirectoryEnumerationOptions) throws -> [URL] {
        try fileManager.contentsOfDirectory(at: url, includingPropertiesForKeys: keys, options: mask)
    }
    
    func attributesOfItem(atPath path: String) throws -> [FileAttributeKey: Any] {
        try fileManager.attributesOfItem(atPath: path)
    }
}
