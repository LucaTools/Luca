//  GitIgnoreManagerSkillsTests.swift

import Foundation
import Testing
@testable import LucaCore

struct GitIgnoreManagerSkillsTests {

    private let fileManager: FileManagerWrapperMock
    private let sut: GitIgnoreManager

    init() {
        fileManager = FileManagerWrapperMock()
        sut = GitIgnoreManager(fileManager: fileManager, printer: PrinterMock())
    }

    @Test
    func test_ensureGitIgnoreIncludesSkillFolders_whenNotGitRepo_doesNothing() throws {
        let currentDirectory = URL(fileURLWithPath: fileManager.currentDirectoryPath)
        try fileManager.createDirectory(at: currentDirectory, withIntermediateDirectories: true)
        let agents = [
            AgentInfo(id: "claude-code", projectSkillsPath: ".claude/skills"),
            AgentInfo(id: "cursor", projectSkillsPath: ".cursor/rules")
        ]

        try sut.ensureGitIgnoreIncludesSkillFolders(agents: agents)

        let gitIgnoreFile = currentDirectory.appending(component: ".gitignore")
        #expect(fileManager.fileExists(atPath: gitIgnoreFile.path) == false)
    }

    @Test
    func test_ensureGitIgnoreIncludesSkillFolders_createsGitIgnoreWithAllEntries() throws {
        let currentDirectory = URL(fileURLWithPath: fileManager.currentDirectoryPath)
        try fileManager.createDirectory(at: currentDirectory, withIntermediateDirectories: true)
        let gitDirectory = currentDirectory.appending(component: ".git")
        try fileManager.createDirectory(at: gitDirectory, withIntermediateDirectories: true)
        let agents = [
            AgentInfo(id: "claude-code", projectSkillsPath: ".claude/skills"),
            AgentInfo(id: "cursor", projectSkillsPath: ".cursor/rules")
        ]

        try sut.ensureGitIgnoreIncludesSkillFolders(agents: agents)

        let gitIgnoreFile = currentDirectory.appending(component: ".gitignore")
        #expect(fileManager.fileExists(atPath: gitIgnoreFile.path))
        let content = try fileManager.readString(at: gitIgnoreFile)
        #expect(content == ".luca/skills\n.claude/skills\n.cursor/rules\n")
    }

    @Test
    func test_ensureGitIgnoreIncludesSkillFolders_appendsEntries() throws {
        let currentDirectory = URL(fileURLWithPath: fileManager.currentDirectoryPath)
        try fileManager.createDirectory(at: currentDirectory, withIntermediateDirectories: true)
        let gitDirectory = currentDirectory.appending(component: ".git")
        try fileManager.createDirectory(at: gitDirectory, withIntermediateDirectories: true)
        let gitIgnoreFile = currentDirectory.appending(component: ".gitignore")
        try fileManager.writeString("existing\n", to: gitIgnoreFile)
        let agents = [
            AgentInfo(id: "claude-code", projectSkillsPath: ".claude/skills")
        ]

        try sut.ensureGitIgnoreIncludesSkillFolders(agents: agents)

        let content = try fileManager.readString(at: gitIgnoreFile)
        #expect(content == "existing\n.luca/skills\n.claude/skills\n")
    }

    @Test
    func test_ensureGitIgnoreIncludesSkillFolders_doesNotDuplicate() throws {
        let currentDirectory = URL(fileURLWithPath: fileManager.currentDirectoryPath)
        try fileManager.createDirectory(at: currentDirectory, withIntermediateDirectories: true)
        let gitDirectory = currentDirectory.appending(component: ".git")
        try fileManager.createDirectory(at: gitDirectory, withIntermediateDirectories: true)
        let gitIgnoreFile = currentDirectory.appending(component: ".gitignore")
        try fileManager.writeString(".luca/skills\n.claude/skills\n", to: gitIgnoreFile)
        let agents = [
            AgentInfo(id: "claude-code", projectSkillsPath: ".claude/skills")
        ]

        try sut.ensureGitIgnoreIncludesSkillFolders(agents: agents)

        let content = try fileManager.readString(at: gitIgnoreFile)
        #expect(content == ".luca/skills\n.claude/skills\n")
    }

    @Test
    func test_ensureGitIgnoreIncludesSkillFolders_appendsNewlineAndEntriesWhenNoTrailingNewline() throws {
        let currentDirectory = URL(fileURLWithPath: fileManager.currentDirectoryPath)
        try fileManager.createDirectory(at: currentDirectory, withIntermediateDirectories: true)
        let gitDirectory = currentDirectory.appending(component: ".git")
        try fileManager.createDirectory(at: gitDirectory, withIntermediateDirectories: true)
        let gitIgnoreFile = currentDirectory.appending(component: ".gitignore")
        try fileManager.writeString("existing", to: gitIgnoreFile)
        let agents = [
            AgentInfo(id: "claude-code", projectSkillsPath: ".claude/skills")
        ]

        try sut.ensureGitIgnoreIncludesSkillFolders(agents: agents)

        let content = try fileManager.readString(at: gitIgnoreFile)
        #expect(content.hasPrefix("existing\n"))
        #expect(content.contains(".luca/skills\n"))
        #expect(content.contains(".claude/skills\n"))
    }

    @Test
    func test_ensureGitIgnoreIncludesSkillFolders_emptyAgents_onlyAddsSkillsEntry() throws {
        let currentDirectory = URL(fileURLWithPath: fileManager.currentDirectoryPath)
        try fileManager.createDirectory(at: currentDirectory, withIntermediateDirectories: true)
        let gitDirectory = currentDirectory.appending(component: ".git")
        try fileManager.createDirectory(at: gitDirectory, withIntermediateDirectories: true)

        try sut.ensureGitIgnoreIncludesSkillFolders(agents: [])

        let gitIgnoreFile = currentDirectory.appending(component: ".gitignore")
        #expect(fileManager.fileExists(atPath: gitIgnoreFile.path))
        let content = try fileManager.readString(at: gitIgnoreFile)
        #expect(content == ".luca/skills\n")
    }
}
