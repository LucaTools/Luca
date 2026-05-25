//  InstalledSkillsListerTests.swift

import Foundation
import Testing
@testable import LucaCore
@testable import ManagerCore

struct InstalledSkillsListerTests {

    @Test
    func test_installedSkills_emptyFolder() throws {
        let fileManager = FileManagerWrapperMock()
        let lister = InstalledSkillsLister(fileManager: fileManager)

        // skillsCacheFolder does not exist (mock uses temp dir which is empty initially)

        let skills = try lister.installedSkills()
        #expect(skills.isEmpty)
    }

    @Test
    func test_installedSkills_multipleSkills() throws {
        let fileManager = FileManagerWrapperMock()
        let lister = InstalledSkillsLister(fileManager: fileManager)

        let skillNames = ["release-prep", "find-skills"]
        for name in skillNames {
            let skillFolder = fileManager.skillsCacheFolder.appending(component: name)
            try fileManager.createDirectory(at: skillFolder, withIntermediateDirectories: true)
        }

        let skills = try lister.installedSkills()
        #expect(skills == ["find-skills", "release-prep"])
    }

    @Test
    func test_installedSkills_skipsNonDirectories() throws {
        let fileManager = FileManagerWrapperMock()
        let lister = InstalledSkillsLister(fileManager: fileManager)

        try fileManager.createDirectory(at: fileManager.skillsCacheFolder, withIntermediateDirectories: true)

        // Place a regular file inside the skills cache folder (should be silently skipped)
        let filePath = fileManager.skillsCacheFolder.appending(component: "not-a-skill.txt").path
        _ = fileManager.createFile(atPath: filePath, contents: Data("content".utf8))

        // Create a valid skill directory alongside the file
        let skillFolder = fileManager.skillsCacheFolder.appending(component: "valid-skill")
        try fileManager.createDirectory(at: skillFolder, withIntermediateDirectories: true)

        let skills = try lister.installedSkills()
        #expect(skills == ["valid-skill"])
    }

    @Test
    func test_installedSkills_whenGlobal_listsFromGlobalSkillsCacheFolder() throws {
        let fileManager = FileManagerWrapperMock()
        let lister = InstalledSkillsLister(fileManager: fileManager)

        let skillName = "global-skill"
        let skillFolder = fileManager.globalSkillsCacheFolder.appending(component: skillName)
        try fileManager.createDirectory(at: skillFolder, withIntermediateDirectories: true)

        let skills = try lister.installedSkills(isGlobal: true)
        #expect(skills == [skillName])
    }

    @Test
    func test_installedSkills_whenGlobal_andNoGlobalFolder_returnsEmptyArray() throws {
        let fileManager = FileManagerWrapperMock()
        let lister = InstalledSkillsLister(fileManager: fileManager)

        // globalSkillsCacheFolder does not exist — no directories created
        let skills = try lister.installedSkills(isGlobal: true)
        #expect(skills.isEmpty)
    }
}
