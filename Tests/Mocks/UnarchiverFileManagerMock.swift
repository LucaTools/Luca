//  UnarchiverFileManagerMock.swift

import Foundation
@testable import LucaFoundation
@testable import ManagerCore

class UnarchiverFileManagerMock: UnarchiverFileManaging {
    
    private(set) var fileManager: FileManager
    
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

    func createDirectory(at url: URL, withIntermediateDirectories: Bool) throws {
        try fileManager.createDirectory(at: url, withIntermediateDirectories: withIntermediateDirectories)
    }
}
