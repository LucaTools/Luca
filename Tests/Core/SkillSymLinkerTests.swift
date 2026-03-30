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
            AgentInfo(id: "claude-code", projectSkillsPath: ".claude/skills"),
            AgentInfo(id: "cursor", projectSkillsPath: ".cursor/skills")
        ]

        let symLinkerFileManager = SkillSymLinkerFileManagerMock(fileManager: fileManager)
        let sut = SkillSymLinker(fileManager: symLinkerFileManager)

        try sut.setSymLink(skillName: skillName, agents: agents)

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
            AgentInfo(id: "claude-code", projectSkillsPath: ".claude/skills")
        ]

        let symLinkerFileManager = SkillSymLinkerFileManagerMock(fileManager: fileManager)
        let sut = SkillSymLinker(fileManager: symLinkerFileManager)

        // Create symlink the first time
        try sut.setSymLink(skillName: skillName, agents: agents)

        let expectedSymLink = URL(fileURLWithPath: symLinkerFileManager.currentDirectoryPath)
            .appending(path: agents[0].projectSkillsPath)
            .appending(component: skillName)
        #expect(symLinkExists(atPath: expectedSymLink.path))

        // Create symlink a second time (idempotent — should remove and recreate)
        try sut.setSymLink(skillName: skillName, agents: agents)

        #expect(symLinkExists(atPath: expectedSymLink.path))
    }

    @Test
    func test_setSymLink_createsAgentDirectory() throws {
        let skillName = "find-skills"
        let agentSkillsPath = ".claude/skills"
        let agents = [
            AgentInfo(id: "claude-code", projectSkillsPath: agentSkillsPath)
        ]

        let symLinkerFileManager = SkillSymLinkerFileManagerMock(fileManager: fileManager)
        let sut = SkillSymLinker(fileManager: symLinkerFileManager)

        let agentSkillsDir = URL(fileURLWithPath: symLinkerFileManager.currentDirectoryPath)
            .appending(path: agentSkillsPath)

        var isDirectory: ObjCBool = false
        #expect(!fileManager.fileExists(atPath: agentSkillsDir.path, isDirectory: &isDirectory))

        try sut.setSymLink(skillName: skillName, agents: agents)

        #expect(fileManager.fileExists(atPath: agentSkillsDir.path, isDirectory: &isDirectory))
        #expect(isDirectory.boolValue)
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

    init(fileManager: FileManager = .default) {
        self.fileManager = fileManager
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
