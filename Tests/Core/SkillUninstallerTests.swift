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
            AgentInfo(id: "claude-code", projectSkillsPath: ".claude/skills"),
            AgentInfo(id: "cursor", projectSkillsPath: ".cursor/skills")
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
            AgentInfo(id: "claude-code", projectSkillsPath: ".claude/skills")
        ]

        // Create the skill cache folder but no agent symlinks
        let skillFolder = fileManager.skillsCacheFolder.appending(component: skillName)
        try fileManager.createDirectory(at: skillFolder, withIntermediateDirectories: true)

        // Should not throw even though the agent symlink doesn't exist
        try uninstaller.uninstall(skillName: skillName, agents: agents)

        #expect(!fileManager.fileExists(atPath: skillFolder.path))
    }
}
