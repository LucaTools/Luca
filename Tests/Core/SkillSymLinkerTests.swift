//  SkillSymLinkerTests.swift

import Foundation
import Testing
@testable import LucaCore

struct SkillSymLinkerTests {

    private let fileManager: FileManager = .default

    @Test
    func test_setSymLink_createsSymlinksForAllAgents() throws {
        let skillName = "find-skills"
        let agents = [
            AgentInfo(id: "claude-code", projectSkillsPath: ".claude/skills", globalSkillsPath: "~/.claude/skills"),
            AgentInfo(id: "cursor", projectSkillsPath: ".cursor/skills", globalSkillsPath: "~/.cursor/skills")
        ]

        let symLinkerFileManager = SkillSymLinkerFileManagerMock(fileManager: fileManager)
        let sut = SkillSymLinker(fileManager: symLinkerFileManager)

        try sut.setSymLink(skillName: skillName, agents: agents, isGlobal: false)

        for agentInfo in agents {
            let expectedSymLink = URL(fileURLWithPath: symLinkerFileManager.currentDirectoryPath)
                .appending(path: agentInfo.projectSkillsPath)
                .appending(component: skillName)
            #expect(symLinkExists(atPath: expectedSymLink.path))
        }
    }

    @Test
    func test_setSymLink_removesExistingSymlink() throws {
        let skillName = "find-skills"
        let agents = [
            AgentInfo(id: "claude-code", projectSkillsPath: ".claude/skills", globalSkillsPath: "~/.claude/skills")
        ]

        let symLinkerFileManager = SkillSymLinkerFileManagerMock(fileManager: fileManager)
        let sut = SkillSymLinker(fileManager: symLinkerFileManager)

        // Create symlink the first time
        try sut.setSymLink(skillName: skillName, agents: agents, isGlobal: false)

        let expectedSymLink = URL(fileURLWithPath: symLinkerFileManager.currentDirectoryPath)
            .appending(path: agents[0].projectSkillsPath)
            .appending(component: skillName)
        #expect(symLinkExists(atPath: expectedSymLink.path))

        // Create symlink a second time (idempotent — should remove and recreate)
        try sut.setSymLink(skillName: skillName, agents: agents, isGlobal: false)

        #expect(symLinkExists(atPath: expectedSymLink.path))
    }

    @Test
    func test_setSymLink_createsAgentDirectory() throws {
        let skillName = "find-skills"
        let agentSkillsPath = ".claude/skills"
        let agents = [
            AgentInfo(id: "claude-code", projectSkillsPath: agentSkillsPath, globalSkillsPath: "~/.claude/skills")
        ]

        let symLinkerFileManager = SkillSymLinkerFileManagerMock(fileManager: fileManager)
        let sut = SkillSymLinker(fileManager: symLinkerFileManager)

        let agentSkillsDir = URL(fileURLWithPath: symLinkerFileManager.currentDirectoryPath)
            .appending(path: agentSkillsPath)

        var isDirectory: ObjCBool = false
        #expect(!fileManager.fileExists(atPath: agentSkillsDir.path, isDirectory: &isDirectory))

        try sut.setSymLink(skillName: skillName, agents: agents, isGlobal: false)

        #expect(fileManager.fileExists(atPath: agentSkillsDir.path, isDirectory: &isDirectory))
        #expect(isDirectory.boolValue)
    }

    @Test
    func test_setSymLink_directoryCreationFails_throwsAgentDirectoryCreationFailed() throws {
        let skillName = "find-skills"
        let agents = [
            AgentInfo(id: "claude-code", projectSkillsPath: ".claude/skills", globalSkillsPath: "~/.claude/skills")
        ]

        let symLinkerFileManager = FailingDirectoryCreationFileManagerMock()
        let sut = SkillSymLinker(fileManager: symLinkerFileManager)

        do {
            try sut.setSymLink(skillName: skillName, agents: agents, isGlobal: false)
            Issue.record("Expected error to be thrown")
        } catch let error as SkillSymLinker.SkillSymLinkerError {
            if case .agentDirectoryCreationFailed = error {
                // Expected
            } else {
                Issue.record("Expected agentDirectoryCreationFailed, got \(error)")
            }
        }
    }

    @Test
    func test_setSymLink_symLinkCreationFails_throwsSymLinkCreationFailed() throws {
        let skillName = "find-skills"
        let agents = [
            AgentInfo(id: "claude-code", projectSkillsPath: ".claude/skills", globalSkillsPath: "~/.claude/skills")
        ]

        let symLinkerFileManager = FailingSymLinkCreationFileManagerMock(fileManager: fileManager)
        let sut = SkillSymLinker(fileManager: symLinkerFileManager)

        do {
            try sut.setSymLink(skillName: skillName, agents: agents, isGlobal: false)
            Issue.record("Expected error to be thrown")
        } catch let error as SkillSymLinker.SkillSymLinkerError {
            if case .symLinkCreationFailed = error {
                // Expected
            } else {
                Issue.record("Expected symLinkCreationFailed, got \(error)")
            }
        }
    }

    @Test
    func test_setSymLink_whenGlobal_usesGlobalSourcePath() throws {
        let skillName = "global-skill"
        let agents = [
            AgentInfo(id: "claude-code", projectSkillsPath: ".claude/skills", globalSkillsPath: "~/.claude/skills")
        ]

        let symLinkerFileManager = SkillSymLinkerFileManagerMock(fileManager: fileManager)
        let sut = SkillSymLinker(fileManager: symLinkerFileManager)

        try sut.setSymLink(skillName: skillName, agents: agents, isGlobal: true)

        let expectedSource = symLinkerFileManager.globalSkillsCacheFolder.appending(component: skillName)
        let agentGlobalDir = agents[0].resolvedGlobalSkillsPath(homeDirectory: symLinkerFileManager.homeDirectoryForCurrentUser)
        let symLinkDestination = agentGlobalDir.appending(component: skillName)

        // Verify the symlink at the destination points back to the global source
        let resolvedDestination = try fileManager.destinationOfSymbolicLink(atPath: symLinkDestination.path)
        #expect(resolvedDestination == expectedSource.path)
    }

    @Test
    func test_setSymLink_whenGlobal_usesGlobalDestinationPath() throws {
        let skillName = "global-skill"
        let agents = [
            AgentInfo(id: "claude-code", projectSkillsPath: ".claude/skills", globalSkillsPath: "~/.claude/skills")
        ]

        let symLinkerFileManager = SkillSymLinkerFileManagerMock(fileManager: fileManager)
        let sut = SkillSymLinker(fileManager: symLinkerFileManager)

        try sut.setSymLink(skillName: skillName, agents: agents, isGlobal: true)

        let agentGlobalDir = agents[0].resolvedGlobalSkillsPath(homeDirectory: symLinkerFileManager.homeDirectoryForCurrentUser)
        let expectedSymLink = agentGlobalDir.appending(component: skillName)

        #expect(symLinkExists(atPath: expectedSymLink.path))
    }

    @Test
    func test_setSymLink_whenNotGlobal_usesProjectRelativePaths() throws {
        let skillName = "local-skill"
        let agents = [
            AgentInfo(id: "claude-code", projectSkillsPath: ".claude/skills", globalSkillsPath: "~/.claude/skills")
        ]

        let symLinkerFileManager = SkillSymLinkerFileManagerMock(fileManager: fileManager)
        let sut = SkillSymLinker(fileManager: symLinkerFileManager)

        try sut.setSymLink(skillName: skillName, agents: agents, isGlobal: false)

        // Symlink should be at CWD/.claude/skills/<skillName>
        let expectedSymLink = URL(fileURLWithPath: symLinkerFileManager.currentDirectoryPath)
            .appending(path: agents[0].projectSkillsPath)
            .appending(component: skillName)
        #expect(symLinkExists(atPath: expectedSymLink.path))

        // It should NOT exist under the global agent dir
        let agentGlobalDir = agents[0].resolvedGlobalSkillsPath(homeDirectory: symLinkerFileManager.homeDirectoryForCurrentUser)
        let globalSymLink = agentGlobalDir.appending(component: skillName)
        #expect(!symLinkExists(atPath: globalSymLink.path))
    }

    // MARK: - Private

    private func symLinkExists(atPath path: String) -> Bool {
        do {
            let attributes = try fileManager.attributesOfItem(atPath: path)
            if let fileType = attributes[.type] as? FileAttributeType {
                return fileType == .typeSymbolicLink
            }
            return false
        } catch {
            return false
        }
    }
}

// MARK: -

private class SkillSymLinkerFileManagerMock: SkillSymLinkerFileManaging {

    private(set) var fileManager: FileManager

    private var _currentDirectoryPath: String?
    private var _homeDirectoryForCurrentUser: URL?

    init(fileManager: FileManager = .default) {
        self.fileManager = fileManager
    }

    var homeDirectoryForCurrentUser: URL {
        if let existing = _homeDirectoryForCurrentUser { return existing }
        let url = fileManager.temporaryDirectory.appending(component: UUID().uuidString)
        try? fileManager.createDirectory(at: url, withIntermediateDirectories: true)
        _homeDirectoryForCurrentUser = url
        return url
    }

    var globalSkillsCacheFolder: URL {
        homeDirectoryForCurrentUser.appending(components: ".luca", "skills")
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

    func removeItem(at url: URL) throws {
        try fileManager.removeItem(at: url)
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
}

private class FailingDirectoryCreationFileManagerMock: SkillSymLinkerFileManaging {

    var globalSkillsCacheFolder: URL { URL(fileURLWithPath: "/tmp/.luca/skills") }
    var homeDirectoryForCurrentUser: URL { URL(fileURLWithPath: "/tmp") }
    var currentDirectoryPath: String { "/tmp/\(UUID().uuidString)" }

    func fileExists(atPath path: String) -> Bool { false }
    func removeItem(at url: URL) throws {}
    func createDirectory(at url: URL, withIntermediateDirectories: Bool) throws {
        throw NSError(domain: "test", code: 1, userInfo: [NSLocalizedDescriptionKey: "Permission denied"])
    }
    func createSymbolicLink(at url: URL, withDestinationURL destinationURL: URL) throws {}
    func attributesOfItem(atPath path: String) throws -> [FileAttributeKey: Any] { [:] }
}

private class FailingSymLinkCreationFileManagerMock: SkillSymLinkerFileManaging {

    private let fileManager: FileManager
    private var _currentDirectoryPath: String?
    private var _homeDirectoryForCurrentUser: URL?

    init(fileManager: FileManager) {
        self.fileManager = fileManager
    }

    var homeDirectoryForCurrentUser: URL {
        if let existing = _homeDirectoryForCurrentUser { return existing }
        let url = fileManager.temporaryDirectory.appending(component: UUID().uuidString)
        try? fileManager.createDirectory(at: url, withIntermediateDirectories: true)
        _homeDirectoryForCurrentUser = url
        return url
    }

    var globalSkillsCacheFolder: URL {
        homeDirectoryForCurrentUser.appending(components: ".luca", "skills")
    }

    var currentDirectoryPath: String {
        if let _currentDirectoryPath { return _currentDirectoryPath }
        let path = fileManager.temporaryDirectory.appending(component: UUID().uuidString).path
        _currentDirectoryPath = path
        return path
    }

    func fileExists(atPath path: String) -> Bool { false }
    func removeItem(at url: URL) throws {}
    func createDirectory(at url: URL, withIntermediateDirectories: Bool) throws {
        try fileManager.createDirectory(at: url, withIntermediateDirectories: withIntermediateDirectories)
    }
    func createSymbolicLink(at url: URL, withDestinationURL destinationURL: URL) throws {
        throw NSError(domain: "test", code: 1, userInfo: [NSLocalizedDescriptionKey: "Symlink failed"])
    }
    func attributesOfItem(atPath path: String) throws -> [FileAttributeKey: Any] { [:] }
}
