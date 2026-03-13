//  SpecFinderTests.swift

import Foundation
import Testing
@testable import LucaCore

struct SpecFinderTests {

    // MARK: - Helpers

    private func makeDirectory(fileManager: FileManagerWrapperMock) throws -> URL {
        let directory = URL(fileURLWithPath: fileManager.currentDirectoryPath)
        try fileManager.createDirectory(at: directory, withIntermediateDirectories: true)
        return directory
    }

    private func createFile(named name: String, in directory: URL, fileManager: FileManagerWrapperMock) throws {
        let filePath = directory.appending(component: name)
        try "".write(to: filePath, atomically: true, encoding: .utf8)
    }

    // MARK: - Tests

    @Test
    func findSpecFiles_noFiles_returnsEmpty() throws {
        let fileManager = FileManagerWrapperMock()
        let directory = try makeDirectory(fileManager: fileManager)
        let finder = SpecFinder(fileManager: fileManager)

        let result = try finder.findSpecFiles(in: directory)

        #expect(result.isEmpty)
    }

    @Test
    func findSpecFiles_exactLucafile_returnsIt() throws {
        let fileManager = FileManagerWrapperMock()
        let directory = try makeDirectory(fileManager: fileManager)
        try createFile(named: Constants.specFile, in: directory, fileManager: fileManager)
        let finder = SpecFinder(fileManager: fileManager)

        let result = try finder.findSpecFiles(in: directory)

        #expect(result.count == 1)
        #expect(result[0].lastPathComponent == Constants.specFile)
    }

    @Test
    func findSpecFiles_multipleVariants_returnsAllSorted() throws {
        let fileManager = FileManagerWrapperMock()
        let directory = try makeDirectory(fileManager: fileManager)
        try createFile(named: "\(Constants.specFile)-production", in: directory, fileManager: fileManager)
        try createFile(named: "\(Constants.specFile)-dev", in: directory, fileManager: fileManager)
        try createFile(named: "\(Constants.specFile)-macOS", in: directory, fileManager: fileManager)
        let finder = SpecFinder(fileManager: fileManager)

        let result = try finder.findSpecFiles(in: directory)

        let names = result.map { $0.lastPathComponent }
        #expect(names == ["\(Constants.specFile)-dev", "\(Constants.specFile)-macOS", "\(Constants.specFile)-production"])
    }

    @Test
    func findSpecFiles_mixedFiles_onlyReturnsLucafilePrefixed() throws {
        let fileManager = FileManagerWrapperMock()
        let directory = try makeDirectory(fileManager: fileManager)
        try createFile(named: "\(Constants.specFile)", in: directory, fileManager: fileManager)
        try createFile(named: "\(Constants.specFile)-dev", in: directory, fileManager: fileManager)
        try createFile(named: "README.md", in: directory, fileManager: fileManager)
        try createFile(named: "Package.swift", in: directory, fileManager: fileManager)
        let finder = SpecFinder(fileManager: fileManager)

        let result = try finder.findSpecFiles(in: directory)

        let names = result.map { $0.lastPathComponent }
        #expect(names == ["\(Constants.specFile)", "\(Constants.specFile)-dev"])
    }

    @Test
    func findSpecFiles_exactAndVariants_returnsAll() throws {
        let fileManager = FileManagerWrapperMock()
        let directory = try makeDirectory(fileManager: fileManager)
        try createFile(named: "\(Constants.specFile)", in: directory, fileManager: fileManager)
        try createFile(named: "\(Constants.specFile)-production", in: directory, fileManager: fileManager)
        try createFile(named: "\(Constants.specFile)-Linux", in: directory, fileManager: fileManager)
        let finder = SpecFinder(fileManager: fileManager)

        let result = try finder.findSpecFiles(in: directory)

        let names = result.map { $0.lastPathComponent }
        #expect(names == ["\(Constants.specFile)", "\(Constants.specFile)-Linux", "\(Constants.specFile)-production"])
    }

    @Test
    func findSpecFiles_ymlExtension_returnsIt() throws {
        let fileManager = FileManagerWrapperMock()
        let directory = try makeDirectory(fileManager: fileManager)
        let ymlName = "\(Constants.specFile).\(Constants.ymlExtension)"
        try createFile(named: ymlName, in: directory, fileManager: fileManager)
        let finder = SpecFinder(fileManager: fileManager)

        let result = try finder.findSpecFiles(in: directory)

        #expect(result.count == 1)
        #expect(result[0].lastPathComponent == ymlName)
    }

    @Test
    func findSpecFiles_ymlAndVariants_returnsAllSorted() throws {
        let fileManager = FileManagerWrapperMock()
        let directory = try makeDirectory(fileManager: fileManager)
        let ymlName = "\(Constants.specFile).\(Constants.ymlExtension)"
        try createFile(named: "\(Constants.specFile)", in: directory, fileManager: fileManager)
        try createFile(named: ymlName, in: directory, fileManager: fileManager)
        try createFile(named: "\(Constants.specFile)-dev", in: directory, fileManager: fileManager)
        let finder = SpecFinder(fileManager: fileManager)

        let result = try finder.findSpecFiles(in: directory)

        let names = result.map { $0.lastPathComponent }
        // '-' (ASCII 45) sorts before '.' (ASCII 46), so Lucafile-dev < Lucafile.yml
        #expect(names == ["\(Constants.specFile)", "\(Constants.specFile)-dev", ymlName])
    }
}
