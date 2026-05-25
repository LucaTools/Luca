//  GlobalSpecFinderTests.swift

import Foundation
import Testing
@testable import LucaCore

struct GlobalSpecFinderTests {

    // MARK: - Helpers

    private func globalConfigDir(fileManager: FileManagerWrapperMock) -> URL {
        fileManager.homeDirectoryForCurrentUser.appending(components: ".config", "luca")
    }

    private func createFile(named name: String, in directory: URL, fileManager: FileManagerWrapperMock) throws {
        try fileManager.createDirectory(at: directory, withIntermediateDirectories: true)
        _ = fileManager.fileManager.createFile(atPath: directory.appending(component: name).path, contents: nil)
    }

    // MARK: - Tests

    @Test
    func findGlobalSpec_lucafileExists_returnsIt() throws {
        let fileManager = FileManagerWrapperMock()
        let dir = globalConfigDir(fileManager: fileManager)
        try createFile(named: Constants.specFile, in: dir, fileManager: fileManager)
        let finder = GlobalSpecFinder(fileManager: fileManager)

        let result = try finder.findGlobalSpec()

        #expect(result.lastPathComponent == Constants.specFile)
    }

    @Test
    func findGlobalSpec_toolfileExists_returnsIt() throws {
        let fileManager = FileManagerWrapperMock()
        let dir = globalConfigDir(fileManager: fileManager)
        try createFile(named: Constants.toolFile, in: dir, fileManager: fileManager)
        let finder = GlobalSpecFinder(fileManager: fileManager)

        let result = try finder.findGlobalSpec()

        #expect(result.lastPathComponent == Constants.toolFile)
    }

    @Test
    func findGlobalSpec_skillfileExists_returnsIt() throws {
        let fileManager = FileManagerWrapperMock()
        let dir = globalConfigDir(fileManager: fileManager)
        try createFile(named: Constants.skillFile, in: dir, fileManager: fileManager)
        let finder = GlobalSpecFinder(fileManager: fileManager)

        let result = try finder.findGlobalSpec()

        #expect(result.lastPathComponent == Constants.skillFile)
    }

    @Test
    func findGlobalSpec_ymlVariant_returnsIt() throws {
        let fileManager = FileManagerWrapperMock()
        let dir = globalConfigDir(fileManager: fileManager)
        let ymlName = "\(Constants.specFile).\(Constants.ymlExtension)"
        try createFile(named: ymlName, in: dir, fileManager: fileManager)
        let finder = GlobalSpecFinder(fileManager: fileManager)

        let result = try finder.findGlobalSpec()

        #expect(result.lastPathComponent == ymlName)
    }

    @Test
    func findGlobalSpec_lucafileAndToolfile_prefersLucafile() throws {
        let fileManager = FileManagerWrapperMock()
        let dir = globalConfigDir(fileManager: fileManager)
        try createFile(named: Constants.specFile, in: dir, fileManager: fileManager)
        try createFile(named: Constants.toolFile, in: dir, fileManager: fileManager)
        let finder = GlobalSpecFinder(fileManager: fileManager)

        let result = try finder.findGlobalSpec()

        #expect(result.lastPathComponent == Constants.specFile)
    }

    @Test
    func findGlobalSpec_noFiles_throwsNoSpecFound() throws {
        let fileManager = FileManagerWrapperMock()
        let finder = GlobalSpecFinder(fileManager: fileManager)

        #expect(throws: GlobalSpecFinder.GlobalSpecFinderError.self) {
            try finder.findGlobalSpec()
        }
    }

    @Test
    func noSpecFound_errorDescription_containsPath() throws {
        let path = "/home/user/.config/luca"
        let error = GlobalSpecFinder.GlobalSpecFinderError.noSpecFound(path)

        #expect(error.errorDescription?.contains(path) == true)
    }
}
