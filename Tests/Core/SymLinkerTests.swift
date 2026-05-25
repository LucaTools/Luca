//  SymLinkerTests.swift

import Foundation
import Testing
@testable import LucaCore
@testable import ManagerCore

struct SymLinkerTests {

    private let fileManager: FileManager = .default

    @Test
    func createSymLink_toolExists_binaryPathSpecified() throws {
        let tool = Tool(
            name: "MockTool",
            version: "1.0.0",
            url: URL(string: "https://example.com")!,
            binaryPath: "MockTool",
            desiredBinaryName: nil,
            checksum: nil,
            algorithm: nil,
            ignoreArchCheck: nil
        )

        let symLinkFileManager = SymLinkFileManagerMock(fileManager: fileManager)

        let toolFilePath = symLinkFileManager.toolsFolder
            .appending(components: tool.name, "1.0.0")
            .appending(path: tool.effectiveBinaryPath)
        try fileManager.createDirectory(at: toolFilePath.deletingLastPathComponent(), withIntermediateDirectories: true)
        _ = fileManager.createFile(atPath: toolFilePath.path, contents: Data())

        let sut = SymLinker(fileManager: symLinkFileManager)

        let symLinkPath = symLinkFileManager.symlinksFolder
            .appending(component: tool.expectedBinaryName)
            .path

        #expect(!symLinkExists(atPath: symLinkPath))

        try sut.setSymLink(for: tool)

        #expect(symLinkExists(atPath: symLinkPath))
    }

    @Test
    func createSymLink_toolExists_desiredBinaryNameSpecified() throws {
        let desiredBinaryName = "mocktool"
        let tool = Tool(
            name: "MockTool",
            version: "1.0.0",
            url: URL(string: "https://example.com")!,
            binaryPath: "MockTool",
            desiredBinaryName: desiredBinaryName,
            checksum: nil,
            algorithm: nil,
            ignoreArchCheck: nil
        )

        let symLinkFileManager = SymLinkFileManagerMock(fileManager: fileManager)

        let toolFilePath = symLinkFileManager.toolsFolder
            .appending(components: tool.name, "1.0.0")
            .appending(component: desiredBinaryName)
        try fileManager.createDirectory(at: toolFilePath.deletingLastPathComponent(), withIntermediateDirectories: true)
        _ = fileManager.createFile(atPath: toolFilePath.path, contents: Data())

        let sut = SymLinker(fileManager: symLinkFileManager)

        let symLinkPath = symLinkFileManager.symlinksFolder
            .appending(component: tool.expectedBinaryName)
            .path

        #expect(!symLinkExists(atPath: symLinkPath))

        try sut.setSymLink(for: tool)

        #expect(symLinkExists(atPath: symLinkPath))
    }

    @Test
    func createSymLink_toolExists_nestedBinaryPathSpecified() throws {
        let tool = Tool(
            name: "MockTool",
            version: "1.0.0",
            url: URL(string: "https://example.com")!,
            binaryPath: "bin/MockTool",
            desiredBinaryName: nil,
            checksum: nil,
            algorithm: nil,
            ignoreArchCheck: nil
        )

        let symLinkFileManager = SymLinkFileManagerMock(fileManager: fileManager)

        let toolFilePath = symLinkFileManager.toolsFolder
            .appending(components: tool.name, "1.0.0")
            .appending(path: tool.effectiveBinaryPath)
        try fileManager.createDirectory(at: toolFilePath.deletingLastPathComponent(), withIntermediateDirectories: true)
        _ = fileManager.createFile(atPath: toolFilePath.path, contents: Data())

        let sut = SymLinker(fileManager: symLinkFileManager)

        let symLinkPath = symLinkFileManager.symlinksFolder
            .appending(component: tool.expectedBinaryName)
            .path

        #expect(!symLinkExists(atPath: symLinkPath))

        try sut.setSymLink(for: tool)

        #expect(symLinkExists(atPath: symLinkPath))
    }

    @Test
    func createSymLink_symLinkExists() throws {
        let tool = Tool(
            name: "MockTool",
            version: "1.0.0",
            url: URL(string: "https://example.com")!,
            binaryPath: "MockTool",
            desiredBinaryName: nil,
            checksum: nil,
            algorithm: nil,
            ignoreArchCheck: nil
        )

        let symLinkFileManager = SymLinkFileManagerMock(fileManager: fileManager)

        let toolFolderPath = symLinkFileManager.toolsFolder
            .appending(components: tool.name, "1.0.0")
        try fileManager.createDirectory(at: toolFolderPath, withIntermediateDirectories: true)
        let toolFilePath = toolFolderPath
            .appending(path: tool.effectiveBinaryPath)
        _ = fileManager.createFile(atPath: toolFilePath.path, contents: Data())

        let sut = SymLinker(fileManager: symLinkFileManager)

        let symLinkPath = symLinkFileManager.symlinksFolder
            .appending(component: tool.expectedBinaryName)
            .path

        try sut.setSymLink(for: tool)
        try sut.setSymLink(for: tool)

        #expect(symLinkExists(atPath: symLinkPath))
    }

    @Test
    func createSymLink_toolDoesNotExist() throws {
        let tool = Tool(
            name: "MockTool",
            version: "1.0.0",
            url: URL(string: "https://example.com")!,
            binaryPath: "bin/MockTool",
            desiredBinaryName: nil,
            checksum: nil,
            algorithm: nil,
            ignoreArchCheck: nil
        )

        let symLinkFileManager = SymLinkFileManagerMock(fileManager: fileManager)

        let sut = SymLinker(fileManager: symLinkFileManager)

        let symLinkPath = symLinkFileManager.symlinksFolder
            .appending(component: tool.expectedBinaryName)
            .path

        #expect(!symLinkExists(atPath: symLinkPath))

        let expectedDestination = symLinkFileManager.toolsFolder
            .appending(components: tool.name, tool.version)
            .appending(path: tool.effectiveBinaryPath)

        #expect(
            throws: SymLinker.SymLinkerError.missingBinaryFile(
                binaryName: tool.expectedBinaryName,
                expectedLocation: expectedDestination.path
            )
        ) {
            try sut.setSymLink(for: tool)
        }
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
