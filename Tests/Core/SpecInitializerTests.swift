//  SpecInitializerTests.swift

import Foundation
import Testing
@testable import LucaCore

struct SpecInitializerTests {

    @Test
    func test_createSpec_local_createsFileInCurrentDirectory() throws {
        let fileManager = FileManagerWrapperMock()
        let sut = SpecInitializer(fileManager: fileManager)

        let url = try sut.createSpec(named: "Lucafile", location: .local)

        #expect(url.lastPathComponent == "Lucafile")
        #expect(url.deletingLastPathComponent().path == fileManager.currentDirectoryPath)
        #expect(fileManager.fileExists(atPath: url.path))
    }

    @Test
    func test_createSpec_global_createsFileInConfigDirectory() throws {
        let fileManager = FileManagerWrapperMock()
        let sut = SpecInitializer(fileManager: fileManager)

        let url = try sut.createSpec(named: "Lucafile", location: .global)

        let expectedDirectory = fileManager.homeDirectoryForCurrentUser.appending(components: ".config", "luca")
        #expect(url == expectedDirectory.appending(component: "Lucafile"))
        #expect(fileManager.fileExists(atPath: url.path))
    }

    @Test
    func test_createSpec_global_createsParentDirectoryIfNeeded() throws {
        let fileManager = FileManagerWrapperMock()
        let sut = SpecInitializer(fileManager: fileManager)
        let configDir = fileManager.homeDirectoryForCurrentUser.appending(components: ".config", "luca")
        #expect(!fileManager.fileExists(atPath: configDir.path))

        _ = try sut.createSpec(named: "Lucafile", location: .global)

        #expect(fileManager.fileExists(atPath: configDir.path))
    }

    @Test
    func test_createSpec_writesTemplate() throws {
        let fileManager = FileManagerWrapperMock()
        let sut = SpecInitializer(fileManager: fileManager)

        let url = try sut.createSpec(named: "Lucafile", location: .local)

        let content = try fileManager.readString(at: url)
        #expect(content == SpecInitializer.template)
    }

    @Test
    func test_createSpec_fileAlreadyExists_throwsError() throws {
        let fileManager = FileManagerWrapperMock()
        let sut = SpecInitializer(fileManager: fileManager)
        let url = try sut.createSpec(named: "Lucafile", location: .local)

        #expect(throws: SpecInitializer.SpecInitializerError.fileAlreadyExists(url.path)) {
            try sut.createSpec(named: "Lucafile", location: .local)
        }
    }

    @Test
    func test_createSpec_overwrite_replacesFileContent() throws {
        let fileManager = FileManagerWrapperMock()
        let sut = SpecInitializer(fileManager: fileManager)
        let url = try sut.createSpec(named: "Lucafile", location: .local)
        try fileManager.writeString("existing content", to: url)

        _ = try sut.createSpec(named: "Lucafile", location: .local, overwrite: true)

        let content = try fileManager.readString(at: url)
        #expect(content == SpecInitializer.template)
    }

    @Test
    func test_createSpec_overwrite_doesNotThrowWhenFileExists() throws {
        let fileManager = FileManagerWrapperMock()
        let sut = SpecInitializer(fileManager: fileManager)
        _ = try sut.createSpec(named: "Lucafile", location: .local)

        #expect(throws: Never.self) {
            try sut.createSpec(named: "Lucafile", location: .local, overwrite: true)
        }
    }

    @Test(arguments: Constants.specFiles)
    func test_createSpec_allFilenames(name: String) throws {
        let fileManager = FileManagerWrapperMock()
        let sut = SpecInitializer(fileManager: fileManager)

        let url = try sut.createSpec(named: name, location: .local)

        #expect(url.lastPathComponent == name)
        #expect(fileManager.fileExists(atPath: url.path))
    }

    @Test
    func test_createSpec_returnsCorrectURL() throws {
        let fileManager = FileManagerWrapperMock()
        let sut = SpecInitializer(fileManager: fileManager)

        let url = try sut.createSpec(named: "Toolfile", location: .local)

        let expectedURL = URL(fileURLWithPath: fileManager.currentDirectoryPath).appending(component: "Toolfile")
        #expect(url == expectedURL)
    }

    @Test
    func test_template_containsReposKey() {
        #expect(SpecInitializer.template.contains("repos:"))
    }

    @Test
    func test_template_containsToolsKey() {
        #expect(SpecInitializer.template.contains("tools:"))
    }

    @Test
    func test_template_containsSkillsKey() {
        #expect(SpecInitializer.template.contains("skills:"))
    }
}
