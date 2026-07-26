//  GitIgnoreManagerSkillsTests.swift

import Foundation
import Testing
@testable import LucaFoundation
@testable import ManagerCore

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
            AgentInfo(id: "claude-code", projectSkillsPath: ".claude/skills", globalSkillsPath: "~/.claude/skills"),
            AgentInfo(id: "cursor", projectSkillsPath: ".cursor/rules", globalSkillsPath: "~/.cursor/skills")
        ]

        try sut.ensureGitIgnoreIncludesSkillFolders(agents: agents)

        let gitIgnoreFile = currentDirectory.appending(component: ".gitignore")
        #expect(fileManager.fileExists(atPath: gitIgnoreFile.path) == false)
        let nestedGitIgnore = fileManager.skillsCacheFolder.appending(component: ".gitignore")
        #expect(fileManager.fileExists(atPath: nestedGitIgnore.path) == false)
    }

    @Test
    func test_ensureGitIgnoreIncludesSkillFolders_createsNestedGitIgnoreInSkillsFolder() throws {
        let currentDirectory = URL(fileURLWithPath: fileManager.currentDirectoryPath)
        try fileManager.createDirectory(at: currentDirectory, withIntermediateDirectories: true)
        let gitDirectory = currentDirectory.appending(component: ".git")
        try fileManager.createDirectory(at: gitDirectory, withIntermediateDirectories: true)
        let agents = [
            AgentInfo(id: "claude-code", projectSkillsPath: ".claude/skills", globalSkillsPath: "~/.claude/skills")
        ]

        try sut.ensureGitIgnoreIncludesSkillFolders(agents: agents)

        let nestedGitIgnore = fileManager.skillsCacheFolder.appending(component: ".gitignore")
        #expect(fileManager.fileExists(atPath: nestedGitIgnore.path))
        let content = try fileManager.readString(at: nestedGitIgnore)
        #expect(content == "*\n")
    }

    @Test
    func test_ensureGitIgnoreIncludesSkillFolders_createsGitIgnoreWithAgentEntriesOnly() throws {
        let currentDirectory = URL(fileURLWithPath: fileManager.currentDirectoryPath)
        try fileManager.createDirectory(at: currentDirectory, withIntermediateDirectories: true)
        let gitDirectory = currentDirectory.appending(component: ".git")
        try fileManager.createDirectory(at: gitDirectory, withIntermediateDirectories: true)
        let agents = [
            AgentInfo(id: "claude-code", projectSkillsPath: ".claude/skills", globalSkillsPath: "~/.claude/skills"),
            AgentInfo(id: "cursor", projectSkillsPath: ".cursor/rules", globalSkillsPath: "~/.cursor/skills")
        ]

        try sut.ensureGitIgnoreIncludesSkillFolders(agents: agents)

        let gitIgnoreFile = currentDirectory.appending(component: ".gitignore")
        #expect(fileManager.fileExists(atPath: gitIgnoreFile.path))
        let content = try fileManager.readString(at: gitIgnoreFile)
        #expect(content == ".claude/skills\n.cursor/rules\n")
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
            AgentInfo(id: "claude-code", projectSkillsPath: ".claude/skills", globalSkillsPath: "~/.claude/skills")
        ]

        try sut.ensureGitIgnoreIncludesSkillFolders(agents: agents)

        let content = try fileManager.readString(at: gitIgnoreFile)
        #expect(content == "existing\n.claude/skills\n")
    }

    @Test
    func test_ensureGitIgnoreIncludesSkillFolders_doesNotDuplicate() throws {
        let currentDirectory = URL(fileURLWithPath: fileManager.currentDirectoryPath)
        try fileManager.createDirectory(at: currentDirectory, withIntermediateDirectories: true)
        let gitDirectory = currentDirectory.appending(component: ".git")
        try fileManager.createDirectory(at: gitDirectory, withIntermediateDirectories: true)
        let gitIgnoreFile = currentDirectory.appending(component: ".gitignore")
        try fileManager.writeString(".claude/skills\n", to: gitIgnoreFile)
        let agents = [
            AgentInfo(id: "claude-code", projectSkillsPath: ".claude/skills", globalSkillsPath: "~/.claude/skills")
        ]

        try sut.ensureGitIgnoreIncludesSkillFolders(agents: agents)

        let content = try fileManager.readString(at: gitIgnoreFile)
        #expect(content == ".claude/skills\n")
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
            AgentInfo(id: "claude-code", projectSkillsPath: ".claude/skills", globalSkillsPath: "~/.claude/skills")
        ]

        try sut.ensureGitIgnoreIncludesSkillFolders(agents: agents)

        let content = try fileManager.readString(at: gitIgnoreFile)
        #expect(content.hasPrefix("existing\n"))
        #expect(content.contains(".claude/skills\n"))
    }

    @Test
    func test_ensureGitIgnoreIncludesSkillFolders_emptyAgents_createsNestedGitIgnoreButNoRootGitIgnore() throws {
        let currentDirectory = URL(fileURLWithPath: fileManager.currentDirectoryPath)
        try fileManager.createDirectory(at: currentDirectory, withIntermediateDirectories: true)
        let gitDirectory = currentDirectory.appending(component: ".git")
        try fileManager.createDirectory(at: gitDirectory, withIntermediateDirectories: true)

        try sut.ensureGitIgnoreIncludesSkillFolders(agents: [])

        let nestedGitIgnore = fileManager.skillsCacheFolder.appending(component: ".gitignore")
        #expect(fileManager.fileExists(atPath: nestedGitIgnore.path))
        let rootGitIgnore = currentDirectory.appending(component: ".gitignore")
        #expect(fileManager.fileExists(atPath: rootGitIgnore.path) == false)
    }
}
