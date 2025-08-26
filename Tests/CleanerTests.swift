//  CleanerTests.swift

import XCTest
@testable import LucaCore

class CleanerTests: XCTestCase {

    func test_clean() throws {
        let fileManager = MockFileManagerWrapper()

        let toolsFolder = fileManager.homeDirectoryForCurrentUser
            .appending(components: Constants.toolFolder, Constants.toolsFolder)
        try fileManager.createDirectory(at: toolsFolder, withIntermediateDirectories: true)

        let activeFolder = URL(string: fileManager.currentDirectoryPath)!
            .appending(components: Constants.toolFolder, Constants.activeFolder)
        try fileManager.createDirectory(at: activeFolder, withIntermediateDirectories: true)

        XCTAssertTrue(fileManager.fileExists(atPath: toolsFolder.path))
        XCTAssertTrue(fileManager.fileExists(atPath: activeFolder.path))

        let cleaner = Cleaner(fileManager: fileManager)
        try cleaner.clean()

        XCTAssertFalse(fileManager.fileExists(atPath: toolsFolder.path))
        XCTAssertFalse(fileManager.fileExists(atPath: activeFolder.path))
    }
}
