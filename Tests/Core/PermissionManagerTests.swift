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
