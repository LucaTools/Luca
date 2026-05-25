//  PermissionManagerFileManagerMock.swift

import Foundation
@testable import LucaCore
@testable import ManagerCore

class PermissionManagerFileManagerMock: PermissionManagerFileManaging {
    
    private(set) var fileManager: FileManager
    
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
    
    func attributesOfItem(atPath path: String) throws -> [FileAttributeKey: Any] {
        try fileManager.attributesOfItem(atPath: path)
    }
    
    func setAttributes(_ attributes: [FileAttributeKey : Any], ofItemAtPath path: String) throws {
        try fileManager.setAttributes(attributes, ofItemAtPath: path)
    }
}
