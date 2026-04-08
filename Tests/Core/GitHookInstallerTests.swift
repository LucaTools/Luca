//  GitHookInstallerTests.swift

import XCTest
import Noora
@testable import LucaCore

final class GitHookInstallerTests: XCTestCase {

    var fileManager: FileManagerWrapperMock!
    var printer: PrinterSpyMock!
    var sut: GitHookInstaller!

    override func setUp() {
        super.setUp()
        fileManager = FileManagerWrapperMock()
        printer = PrinterSpyMock()
        sut = GitHookInstaller(fileManager: fileManager, printer: printer)
    }

    override func tearDown() {
        fileManager = nil
        printer = nil
        sut = nil
        super.tearDown()
    }

    // MARK: - Not a Git Repository

    func test_installPostCheckoutHook_whenNotGitRepo_doesNothing() throws {
        // Given
        let currentDirectory = URL(fileURLWithPath: fileManager.currentDirectoryPath)
        try fileManager.createDirectory(at: currentDirectory, withIntermediateDirectories: true)

        // When
        try sut.installPostCheckoutHook()

        // Then
        let hooksDirectory = currentDirectory.appending(components: ".git", "hooks")
        XCTAssertFalse(fileManager.fileExists(atPath: hooksDirectory.path))
        XCTAssertTrue(printer.printedMessages.isEmpty)
    }

    // MARK: - Git Worktree

    func test_installPostCheckoutHook_whenGitWorktree_doesNothing() throws {
        // Given: `.git` is a file (worktree), not a directory
        let currentDirectory = URL(fileURLWithPath: fileManager.currentDirectoryPath)
        try fileManager.createDirectory(at: currentDirectory, withIntermediateDirectories: true)
        let gitFile = currentDirectory.appending(component: ".git")
        _ = fileManager.createFile(atPath: gitFile.path, contents: Data("gitdir: /some/main/repo/.git/worktrees/feature\n".utf8))

        // When
        try sut.installPostCheckoutHook()

        // Then
        XCTAssertTrue(printer.printedMessages.isEmpty)
    }

    // MARK: - Source Hook Missing

    func test_installPostCheckoutHook_whenSourceHookMissing_printsWarning() throws {
        // Given
        let currentDirectory = URL(fileURLWithPath: fileManager.currentDirectoryPath)
        try fileManager.createDirectory(at: currentDirectory, withIntermediateDirectories: true)
        let gitDirectory = currentDirectory.appending(component: ".git")
        try fileManager.createDirectory(at: gitDirectory, withIntermediateDirectories: true)

        // When
        try sut.installPostCheckoutHook()

        // Then
        XCTAssertEqual(printer.printedMessages.count, 1)
        XCTAssertTrue(printer.printedMessages[0].contains("Post-checkout hook source not found"))
    }

    // MARK: - Hook Already Exists (Non-Luca)

    func test_installPostCheckoutHook_whenNonLucaHookExists_skipsInstallation() throws {
        // Given
        let currentDirectory = URL(fileURLWithPath: fileManager.currentDirectoryPath)
        try fileManager.createDirectory(at: currentDirectory, withIntermediateDirectories: true)
        let gitDirectory = currentDirectory.appending(component: ".git")
        try fileManager.createDirectory(at: gitDirectory, withIntermediateDirectories: true)
        let hooksDirectory = gitDirectory.appending(component: "hooks")
        try fileManager.createDirectory(at: hooksDirectory, withIntermediateDirectories: true)

        // Create source hook
        let sourceHookDirectory = fileManager.homeDirectoryForCurrentUser.appending(component: ".luca")
        try fileManager.createDirectory(at: sourceHookDirectory, withIntermediateDirectories: true)
        let sourceHookPath = sourceHookDirectory.appending(component: "post-checkout")
        try fileManager.writeString("#!/bin/sh\necho 'source hook'", to: sourceHookPath)

        // Create existing non-Luca destination hook
        let destinationHookPath = hooksDirectory.appending(component: "post-checkout")
        try fileManager.writeString("#!/bin/sh\necho 'custom hook'", to: destinationHookPath)

        // When
        try sut.installPostCheckoutHook()

        // Then
        let existingContent = try fileManager.readString(at: destinationHookPath)
        XCTAssertEqual(existingContent, "#!/bin/sh\necho 'custom hook'")
        XCTAssertTrue(printer.printedMessages.isEmpty)
    }

    // MARK: - Outdated Luca Hook Gets Replaced

    func test_installPostCheckoutHook_whenOutdatedLucaHookExists_replacesIt() throws {
        // Given
        let currentDirectory = URL(fileURLWithPath: fileManager.currentDirectoryPath)
        try fileManager.createDirectory(at: currentDirectory, withIntermediateDirectories: true)
        let gitDirectory = currentDirectory.appending(component: ".git")
        try fileManager.createDirectory(at: gitDirectory, withIntermediateDirectories: true)
        let hooksDirectory = gitDirectory.appending(component: "hooks")
        try fileManager.createDirectory(at: hooksDirectory, withIntermediateDirectories: true)

        // Create source hook (new version)
        let sourceHookDirectory = fileManager.homeDirectoryForCurrentUser.appending(component: ".luca")
        try fileManager.createDirectory(at: sourceHookDirectory, withIntermediateDirectories: true)
        let sourceHookPath = sourceHookDirectory.appending(component: "post-checkout")
        let newContent = "#!/bin/sh\n# LUCA POST-CHECKOUT GIT HOOK\nluca install --quiet"
        try fileManager.writeString(newContent, to: sourceHookPath)

        // Create existing outdated Luca hook
        let destinationHookPath = hooksDirectory.appending(component: "post-checkout")
        let oldContent = "#!/bin/sh\n# LUCA POST-CHECKOUT GIT HOOK\nluca install --quiet --spec Lucafile"
        try fileManager.writeString(oldContent, to: destinationHookPath)

        // When
        try sut.installPostCheckoutHook()

        // Then
        let updatedContent = try fileManager.readString(at: destinationHookPath)
        XCTAssertEqual(updatedContent, newContent)
        XCTAssertEqual(printer.printedMessages.count, 1)
        XCTAssertTrue(printer.printedMessages[0].contains("Updated post-checkout hook"))
    }

    // MARK: - Up-to-date Luca Hook Skipped

    func test_installPostCheckoutHook_whenLucaHookIsUpToDate_skips() throws {
        // Given
        let currentDirectory = URL(fileURLWithPath: fileManager.currentDirectoryPath)
        try fileManager.createDirectory(at: currentDirectory, withIntermediateDirectories: true)
        let gitDirectory = currentDirectory.appending(component: ".git")
        try fileManager.createDirectory(at: gitDirectory, withIntermediateDirectories: true)
        let hooksDirectory = gitDirectory.appending(component: "hooks")
        try fileManager.createDirectory(at: hooksDirectory, withIntermediateDirectories: true)

        // Create source hook
        let sourceHookDirectory = fileManager.homeDirectoryForCurrentUser.appending(component: ".luca")
        try fileManager.createDirectory(at: sourceHookDirectory, withIntermediateDirectories: true)
        let sourceHookPath = sourceHookDirectory.appending(component: "post-checkout")
        let content = "#!/bin/sh\n# LUCA POST-CHECKOUT GIT HOOK\nluca install --quiet"
        try fileManager.writeString(content, to: sourceHookPath)

        // Create existing identical Luca hook
        let destinationHookPath = hooksDirectory.appending(component: "post-checkout")
        try fileManager.writeString(content, to: destinationHookPath)

        // When
        try sut.installPostCheckoutHook()

        // Then
        let existingContent = try fileManager.readString(at: destinationHookPath)
        XCTAssertEqual(existingContent, content)
        XCTAssertTrue(printer.printedMessages.isEmpty)
    }

    // MARK: - Successful Installation

    func test_installPostCheckoutHook_whenAllConditionsMet_copiesHookAndSetsPermissions() throws {
        // Given
        let currentDirectory = URL(fileURLWithPath: fileManager.currentDirectoryPath)
        try fileManager.createDirectory(at: currentDirectory, withIntermediateDirectories: true)
        let gitDirectory = currentDirectory.appending(component: ".git")
        try fileManager.createDirectory(at: gitDirectory, withIntermediateDirectories: true)
        let hooksDirectory = gitDirectory.appending(component: "hooks")
        try fileManager.createDirectory(at: hooksDirectory, withIntermediateDirectories: true)

        // Create source hook
        let sourceHookDirectory = fileManager.homeDirectoryForCurrentUser.appending(component: ".luca")
        try fileManager.createDirectory(at: sourceHookDirectory, withIntermediateDirectories: true)
        let sourceHookPath = sourceHookDirectory.appending(component: "post-checkout")
        try fileManager.writeString("#!/bin/sh\necho 'post-checkout hook'", to: sourceHookPath)

        // When
        try sut.installPostCheckoutHook()

        // Then
        let destinationHookPath = hooksDirectory.appending(component: "post-checkout")
        XCTAssertTrue(fileManager.fileExists(atPath: destinationHookPath.path))

        let copiedContent = try fileManager.readString(at: destinationHookPath)
        XCTAssertEqual(copiedContent, "#!/bin/sh\necho 'post-checkout hook'")

        let attributes = try fileManager.attributesOfItem(atPath: destinationHookPath.path)
        let permissions = attributes[.posixPermissions] as? Int
        XCTAssertEqual(permissions, 0o755)

        XCTAssertEqual(printer.printedMessages.count, 1)
        XCTAssertTrue(printer.printedMessages[0].contains("Installed post-checkout hook"))
    }
}

// MARK: - PrinterSpyMock

final class PrinterSpyMock: Printing {

    private let noora = Noora()
    var printedMessages: [String] = []

    func printFormatted(_ terminalText: TerminalText) {
        printedMessages.append(noora.format(terminalText))
    }
}
