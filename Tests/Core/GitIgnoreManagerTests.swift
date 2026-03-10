//  GitIgnoreManagerTests.swift

import XCTest
@testable import LucaCore

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
    
    func test_ensureGitIgnoreIncludesActiveFolder_whenNotGitRepo_doesNothing() throws {
        // Given
        let currentDirectory = URL(fileURLWithPath: fileManager.currentDirectoryPath)
        try fileManager.createDirectory(at: currentDirectory, withIntermediateDirectories: true)
        
        // When
        try sut.ensureGitIgnoreIncludesActiveFolder()
        
        // Then
        let gitIgnoreFile = currentDirectory.appending(component: ".gitignore")
        XCTAssertFalse(fileManager.fileExists(atPath: gitIgnoreFile.path))
    }
    
    func test_ensureGitIgnoreIncludesActiveFolder_whenGitRepoAndNoGitIgnore_createsGitIgnore() throws {
        // Given
        let currentDirectory = URL(fileURLWithPath: fileManager.currentDirectoryPath)
        try fileManager.createDirectory(at: currentDirectory, withIntermediateDirectories: true)
        let gitDirectory = currentDirectory.appending(component: ".git")
        try fileManager.createDirectory(at: gitDirectory, withIntermediateDirectories: true)
        
        // When
        try sut.ensureGitIgnoreIncludesActiveFolder()
        
        // Then
        let gitIgnoreFile = currentDirectory.appending(component: ".gitignore")
        XCTAssertTrue(fileManager.fileExists(atPath: gitIgnoreFile.path))
        let content = try fileManager.readString(at: gitIgnoreFile)
        XCTAssertEqual(content, ".luca/tools\n")
    }
    
    func test_ensureGitIgnoreIncludesActiveFolder_whenGitRepoAndGitIgnoreExistsWithoutEntry_appendsEntry() throws {
        // Given
        let currentDirectory = URL(fileURLWithPath: fileManager.currentDirectoryPath)
        try fileManager.createDirectory(at: currentDirectory, withIntermediateDirectories: true)
        let gitDirectory = currentDirectory.appending(component: ".git")
        try fileManager.createDirectory(at: gitDirectory, withIntermediateDirectories: true)
        let gitIgnoreFile = currentDirectory.appending(component: ".gitignore")
        try fileManager.writeString("existing\n", to: gitIgnoreFile)
        
        // When
        try sut.ensureGitIgnoreIncludesActiveFolder()
        
        // Then
        let content = try fileManager.readString(at: gitIgnoreFile)
        XCTAssertEqual(content, "existing\n.luca/tools\n")
    }
    
    func test_ensureGitIgnoreIncludesActiveFolder_whenGitRepoAndGitIgnoreExistsWithEntry_doesNothing() throws {
        // Given
        let currentDirectory = URL(fileURLWithPath: fileManager.currentDirectoryPath)
        try fileManager.createDirectory(at: currentDirectory, withIntermediateDirectories: true)
        let gitDirectory = currentDirectory.appending(component: ".git")
        try fileManager.createDirectory(at: gitDirectory, withIntermediateDirectories: true)
        let gitIgnoreFile = currentDirectory.appending(component: ".gitignore")
        try fileManager.writeString(".luca/tools\n", to: gitIgnoreFile)
        
        // When
        try sut.ensureGitIgnoreIncludesActiveFolder()
        
        // Then
        let content = try fileManager.readString(at: gitIgnoreFile)
        XCTAssertEqual(content, ".luca/tools\n")
    }
    
    func test_ensureGitIgnoreIncludesActiveFolder_whenGitRepoAndGitIgnoreExistsWithoutNewline_appendsNewlineAndEntry() throws {
        // Given
        let currentDirectory = URL(fileURLWithPath: fileManager.currentDirectoryPath)
        try fileManager.createDirectory(at: currentDirectory, withIntermediateDirectories: true)
        let gitDirectory = currentDirectory.appending(component: ".git")
        try fileManager.createDirectory(at: gitDirectory, withIntermediateDirectories: true)
        let gitIgnoreFile = currentDirectory.appending(component: ".gitignore")
        try fileManager.writeString("existing", to: gitIgnoreFile)
        
        // When
        try sut.ensureGitIgnoreIncludesActiveFolder()
        
        // Then
        let content = try fileManager.readString(at: gitIgnoreFile)
        XCTAssertEqual(content, "existing\n.luca/tools\n")
    }
}
