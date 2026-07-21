//  InstalledSkillsListerTests.swift

import Foundation
import Testing
@testable import LucaFoundation
@testable import ManagerCore

struct InstalledSkillsListerTests {

    @Test
    func test_installedSkills_emptyFolder_returnsEmptyDict() throws {
        let fileManager = FileManagerWrapperMock()
        let lister = InstalledSkillsLister(fileManager: fileManager)

        let skills = try lister.installedSkills()
        #expect(skills.isEmpty)
    }

    @Test
    func test_installedSkills_multipleSkillsWithVersions() throws {
        let fileManager = FileManagerWrapperMock()
        let lister = InstalledSkillsLister(fileManager: fileManager)

        let findSkillsV1 = fileManager.skillsCacheFolder.appending(components: "find-skills", "v1.0.0")
        let releasePrepV2 = fileManager.skillsCacheFolder.appending(components: "release-prep", "v2.0.0")
        try fileManager.createDirectory(at: findSkillsV1, withIntermediateDirectories: true)
        try fileManager.createDirectory(at: releasePrepV2, withIntermediateDirectories: true)

        let skills = try lister.installedSkills()
        #expect(skills["find-skills"] == ["v1.0.0"])
        #expect(skills["release-prep"] == ["v2.0.0"])
    }

    @Test
    func test_installedSkills_multipleVersionsSameSkill_returnsSorted() throws {
        let fileManager = FileManagerWrapperMock()
        let lister = InstalledSkillsLister(fileManager: fileManager)

        let v1 = fileManager.skillsCacheFolder.appending(components: "find-skills", "v1.0.0")
        let v2 = fileManager.skillsCacheFolder.appending(components: "find-skills", "v2.0.0")
        try fileManager.createDirectory(at: v1, withIntermediateDirectories: true)
        try fileManager.createDirectory(at: v2, withIntermediateDirectories: true)

        let skills = try lister.installedSkills()
        #expect(skills["find-skills"] == ["v1.0.0", "v2.0.0"])
    }

    @Test
    func test_installedSkills_skipsNonDirectories() throws {
        let fileManager = FileManagerWrapperMock()
        let lister = InstalledSkillsLister(fileManager: fileManager)

        try fileManager.createDirectory(at: fileManager.skillsCacheFolder, withIntermediateDirectories: true)
        let filePath = fileManager.skillsCacheFolder.appending(component: "not-a-skill.txt").path
        _ = fileManager.createFile(atPath: filePath, contents: Data("content".utf8))

        let skillFolder = fileManager.skillsCacheFolder.appending(components: "valid-skill", "v1.0.0")
        try fileManager.createDirectory(at: skillFolder, withIntermediateDirectories: true)

        let skills = try lister.installedSkills()
        #expect(skills.keys.contains("valid-skill"))
        #expect(!skills.keys.contains("not-a-skill.txt"))
    }

    @Test
    func test_installedSkills_whenGlobal_listsFromGlobalSkillsCacheFolder() throws {
        let fileManager = FileManagerWrapperMock()
        let lister = InstalledSkillsLister(fileManager: fileManager)

        let skillFolder = fileManager.globalSkillsCacheFolder.appending(components: "global-skill", "v1.0.0")
        try fileManager.createDirectory(at: skillFolder, withIntermediateDirectories: true)

        let skills = try lister.installedSkills(isGlobal: true)
        #expect(skills["global-skill"] == ["v1.0.0"])
    }

    @Test
    func test_installedSkills_whenGlobal_andNoGlobalFolder_returnsEmptyDict() throws {
        let fileManager = FileManagerWrapperMock()
        let lister = InstalledSkillsLister(fileManager: fileManager)

        let skills = try lister.installedSkills(isGlobal: true)
        #expect(skills.isEmpty)
    }
}
