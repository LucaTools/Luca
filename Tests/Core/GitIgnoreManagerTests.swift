//  GitIgnoreManagerTests.swift

import XCTest
@testable import LucaFoundation
@testable import ManagerCore

final class GitIgnoreManagerTests: XCTestCase {

    var fileManager: FileManagerWrapperMock!
    var sut: GitIgnoreManager!

    override func setUp() {
        super.setUp()
        fileManager = FileManagerWrapperMock()
        sut = GitIgnoreManager(fileManager: fileManager, printer: PrinterMock())
    }

    override func tearDown() {
        fileManager = nil
        sut = nil
        super.tearDown()
    }

    func test_ensureGitIgnoreIncludesSymlinksFolder_whenNotGitRepo_doesNothing() throws {
        // Given
        let currentDirectory = URL(fileURLWithPath: fileManager.currentDirectoryPath)
        try fileManager.createDirectory(at: currentDirectory, withIntermediateDirectories: true)

        // When
        try sut.ensureGitIgnoreIncludesSymlinksFolder()

        // Then
        let nestedGitIgnore = fileManager.symlinksFolder.appending(component: ".gitignore")
        XCTAssertFalse(fileManager.fileExists(atPath: nestedGitIgnore.path))
    }

    func test_ensureGitIgnoreIncludesSymlinksFolder_whenGitRepo_createsNestedGitIgnoreInToolsFolder() throws {
        // Given
        let currentDirectory = URL(fileURLWithPath: fileManager.currentDirectoryPath)
        try fileManager.createDirectory(at: currentDirectory, withIntermediateDirectories: true)
        let gitDirectory = currentDirectory.appending(component: ".git")
        try fileManager.createDirectory(at: gitDirectory, withIntermediateDirectories: true)

        // When
        try sut.ensureGitIgnoreIncludesSymlinksFolder()

        // Then
        let nestedGitIgnore = fileManager.symlinksFolder.appending(component: ".gitignore")
        XCTAssertTrue(fileManager.fileExists(atPath: nestedGitIgnore.path))
        let content = try fileManager.readString(at: nestedGitIgnore)
        XCTAssertEqual(content, "*\n")
    }

    func test_ensureGitIgnoreIncludesSymlinksFolder_whenGitRepo_doesNotTouchRootGitIgnore() throws {
        // Given
        let currentDirectory = URL(fileURLWithPath: fileManager.currentDirectoryPath)
        try fileManager.createDirectory(at: currentDirectory, withIntermediateDirectories: true)
        let gitDirectory = currentDirectory.appending(component: ".git")
        try fileManager.createDirectory(at: gitDirectory, withIntermediateDirectories: true)

        // When
        try sut.ensureGitIgnoreIncludesSymlinksFolder()

        // Then
        let rootGitIgnore = currentDirectory.appending(component: ".gitignore")
        XCTAssertFalse(fileManager.fileExists(atPath: rootGitIgnore.path))
    }

    func test_ensureGitIgnoreIncludesSymlinksFolder_whenSymlinksFolderDoesNotExistYet_createsFolderAndGitIgnore() throws {
        // Given
        let currentDirectory = URL(fileURLWithPath: fileManager.currentDirectoryPath)
        try fileManager.createDirectory(at: currentDirectory, withIntermediateDirectories: true)
        let gitDirectory = currentDirectory.appending(component: ".git")
        try fileManager.createDirectory(at: gitDirectory, withIntermediateDirectories: true)
        XCTAssertFalse(fileManager.fileExists(atPath: fileManager.symlinksFolder.path))

        // When
        try sut.ensureGitIgnoreIncludesSymlinksFolder()

        // Then
        var isDirectory: ObjCBool = false
        XCTAssertTrue(fileManager.fileExists(atPath: fileManager.symlinksFolder.path))
        _ = FileManager.default.fileExists(atPath: fileManager.symlinksFolder.path, isDirectory: &isDirectory)
        XCTAssertTrue(isDirectory.boolValue)
    }

    func test_ensureGitIgnoreIncludesSymlinksFolder_whenNestedGitIgnoreAlreadyPresent_isIdempotent() throws {
        // Given
        let currentDirectory = URL(fileURLWithPath: fileManager.currentDirectoryPath)
        try fileManager.createDirectory(at: currentDirectory, withIntermediateDirectories: true)
        let gitDirectory = currentDirectory.appending(component: ".git")
        try fileManager.createDirectory(at: gitDirectory, withIntermediateDirectories: true)
        try fileManager.createDirectory(at: fileManager.symlinksFolder, withIntermediateDirectories: true)
        let nestedGitIgnore = fileManager.symlinksFolder.appending(component: ".gitignore")
        try fileManager.writeString("*\n", to: nestedGitIgnore)

        // When
        try sut.ensureGitIgnoreIncludesSymlinksFolder()

        // Then
        let content = try fileManager.readString(at: nestedGitIgnore)
        XCTAssertEqual(content, "*\n")
    }
}
