//  SkillUninstallerTests.swift

import Foundation
import Testing
@testable import LucaCore

struct SkillUninstallerTests {

    @Test
    func test_uninstall_removesSkillFolderAndSymlinks() throws {
        let fileManager = FileManagerWrapperMock()
        let uninstaller = SkillUninstaller(fileManager: fileManager, printer: PrinterMock())

        let skillName = "find-skills"
        let agents = [
            AgentInfo(id: "claude-code", projectSkillsPath: ".claude/skills", globalSkillsPath: "~/.claude/skills"),
            AgentInfo(id: "cursor", projectSkillsPath: ".cursor/skills", globalSkillsPath: "~/.cursor/skills")
        ]

        // Create the skill cache folder
        let skillFolder = fileManager.skillsCacheFolder.appending(component: skillName)
        try fileManager.createDirectory(at: skillFolder, withIntermediateDirectories: true)

        // Create agent symlink directories and symlinks
        for agent in agents {
            let agentSkillsDir = URL(fileURLWithPath: fileManager.currentDirectoryPath)
                .appending(path: agent.projectSkillsPath)
            try fileManager.createDirectory(at: agentSkillsDir, withIntermediateDirectories: true)
            let symlinkURL = agentSkillsDir.appending(component: skillName)
            try fileManager.createSymbolicLink(at: symlinkURL, withDestinationURL: skillFolder)
        }

        #expect(fileManager.fileExists(atPath: skillFolder.path))

        try uninstaller.uninstall(skillName: skillName, agents: agents)

        #expect(!fileManager.fileExists(atPath: skillFolder.path))

        for agent in agents {
            let symlinkPath = URL(fileURLWithPath: fileManager.currentDirectoryPath)
                .appending(path: agent.projectSkillsPath)
                .appending(component: skillName)
                .path
            #expect(!fileManager.fileExists(atPath: symlinkPath))
        }
    }

    @Test
    func test_uninstall_skillNotFound() throws {
        let fileManager = FileManagerWrapperMock()
        let uninstaller = SkillUninstaller(fileManager: fileManager, printer: PrinterMock())

        let skillName = "missing-skill"

        #expect(throws: SkillUninstaller.SkillUninstallerError.skillNotFound(name: skillName)) {
            try uninstaller.uninstall(skillName: skillName, agents: [])
        }
    }

    @Test
    func test_uninstall_silentlySkipsMissingAgentSymlinks() throws {
        let fileManager = FileManagerWrapperMock()
        let uninstaller = SkillUninstaller(fileManager: fileManager, printer: PrinterMock())

        let skillName = "find-skills"
        let agents = [
            AgentInfo(id: "claude-code", projectSkillsPath: ".claude/skills", globalSkillsPath: "~/.claude/skills")
        ]

        // Create the skill cache folder but no agent symlinks
        let skillFolder = fileManager.skillsCacheFolder.appending(component: skillName)
        try fileManager.createDirectory(at: skillFolder, withIntermediateDirectories: true)

        // Should not throw even though the agent symlink doesn't exist
        try uninstaller.uninstall(skillName: skillName, agents: agents)

        #expect(!fileManager.fileExists(atPath: skillFolder.path))
    }

    @Test
    func test_uninstall_removesAgentSymlinksEvenWhenBroken() throws {
        let mockFM = SkillUninstallerFileManagerMock()
        let uninstaller = SkillUninstaller(fileManager: mockFM, printer: PrinterMock())

        let skillName = "find-skills"
        let agents = [
            AgentInfo(id: "claude-code", projectSkillsPath: ".claude/skills", globalSkillsPath: "~/.claude/skills")
        ]

        // fileExists returns true for all paths so removeItem(atPath:) is called
        try uninstaller.uninstall(skillName: skillName, agents: agents)

        #expect(mockFM.removedPaths.count == 1)
        #expect(mockFM.removedPaths[0].contains("find-skills"))
    }
}

// MARK: - Private Mock

/// A mock that always reports files as existing, to ensure the `removeItem(atPath:)` branch is covered.
private final class SkillUninstallerFileManagerMock: SkillUninstallerFileManaging {

    var removedURLs: [URL] = []
    var removedPaths: [String] = []

    var skillsCacheFolder: URL {
        URL(fileURLWithPath: "/tmp/luca-test-\(ObjectIdentifier(self).hashValue)/skills")
    }

    var currentDirectoryPath: String { "/tmp/luca-test-\(ObjectIdentifier(self).hashValue)" }

    func fileExists(atPath path: String) -> Bool {
        true
    }

    func removeItem(at url: URL) throws {
        removedURLs.append(url)
    }

    func removeItem(atPath path: String) throws {
        removedPaths.append(path)
    }
}
