//  PermissionManagerTests.swift

import Foundation
import Testing
@testable import LucaCore

struct PermissionManagerTests {

    private let fileManager: FileManager = .default

    @Test
    func setExecutablePermission_pathExists() throws {
        let permissionManagerFileManager = PermissionManagerFileManagerMock(fileManager: fileManager)
        let sut = PermissionManager(fileManager: permissionManagerFileManager)

        let tool = Tool(
            name: "MockTool",
            version: "1.0.0",
            url: URL(string: "https://example.com")!,
            binaryPath: "bin/MockTool",
            desiredBinaryName: nil,
            checksum: nil,
            algorithm: nil
        )

        let binaryPath = permissionManagerFileManager.toolsFolder
            .appending(components: tool.name, tool.version)
            .appending(path: tool.effectiveBinaryPath)
        try fileManager.createDirectory(at: binaryPath.deletingLastPathComponent(), withIntermediateDirectories: true)
        #expect(fileManager.createFile(atPath: binaryPath.path, contents: Data()))

        #expect(!executablePermissionsAreSet(atPath: binaryPath.path))

        try sut.setExecutablePermission(for: tool)

        #expect(executablePermissionsAreSet(atPath: binaryPath.path))
    }

    @Test
    func setExecutablePermission_pathDoesNotExists() throws {
        let permissionManagerFileManager = PermissionManagerFileManagerMock(fileManager: fileManager)
        let sut = PermissionManager(fileManager: permissionManagerFileManager)

        let tool = Tool(
            name: "MockTool",
            version: "1.0.0",
            url: URL(string: "https://example.com")!,
            binaryPath: "bin/MockTool",
            desiredBinaryName: nil,
            checksum: nil,
            algorithm: nil
        )

        let filePath = permissionManagerFileManager.toolsFolder
            .appending(components: tool.name, tool.version)
            .appending(path: tool.effectiveBinaryPath)
            .path

        #expect(throws: PermissionManager.PermissionManagerError.missingFile(filePath)) {
            try sut.setExecutablePermission(for: tool)
        }
    }

    @Test
    func setExecutablePermission_noPosixPermissions_throws() throws {
        let fileManager = NoPosixPermissionsFileManagerMock()
        let sut = PermissionManager(fileManager: fileManager)

        let tool = Tool(
            name: "MockTool",
            version: "1.0.0",
            url: URL(string: "https://example.com")!,
            binaryPath: "bin/MockTool",
            desiredBinaryName: nil,
            checksum: nil,
            algorithm: nil
        )

        let expectedPath = fileManager.toolsFolder
            .appending(components: tool.name, tool.version)
            .appending(path: tool.effectiveBinaryPath)
            .path

        #expect(throws: PermissionManager.PermissionManagerError.unableToRetrievePosixPermissions(expectedPath)) {
            try sut.setExecutablePermission(for: tool)
        }
    }

    // MARK: - Private

    private func executablePermissionsAreSet(atPath path: String) -> Bool {
        do {
            let attributes = try fileManager.attributesOfItem(atPath: path)
            if let permissions = attributes[.posixPermissions] as? NSNumber {
                let mode = permissions.uint16Value
                return (mode & 0o111) != 0
            }
            return false
        } catch {
            return false
        }
    }
}

// MARK: - NoPosixPermissionsFileManagerMock

private struct NoPosixPermissionsFileManagerMock: PermissionManagerFileManaging {
    var toolsFolder: URL { URL(fileURLWithPath: "/tmp/luca-test-noperm/.luca/tools") }
    var activeFolder: URL { URL(fileURLWithPath: "/tmp/luca-test-noperm/.luca/tools") }
    func fileExists(atPath path: String) -> Bool { true }
    func attributesOfItem(atPath path: String) throws -> [FileAttributeKey: Any] { [:] }
    func setAttributes(_ attributes: [FileAttributeKey: Any], ofItemAtPath path: String) throws {}
}
