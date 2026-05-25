//  UnarchiverTests.swift

import Foundation
import Testing
@testable import LucaFoundation
@testable import ManagerCore

struct UnarchiverTests {
    
    @Test(arguments: ["zip", "tar.gz"])
    func unarchive(archiveType: String) throws {
        let unarchiverFileManager = UnarchiverFileManagerMock(fileManager: .default)
        let fileTypeDetectorFileManager = FileTypeDetectorFileManagerMock(fileManager: .default)
        let fileTypeDetector = FileTypeDetector(fileManager: fileTypeDetectorFileManager)
        let sut = Unarchiver(fileManager: unarchiverFileManager, fileTypeDetector: fileTypeDetector)

        let installationDestination = unarchiverFileManager.toolsFolder
            .appending(components: "Mock", "1.2.0")

        try unarchiverFileManager.createDirectory(at: installationDestination, withIntermediateDirectories: true)

        let bundle = Bundle.module
        let fixture = Fixture(filename: "MockContent", type: archiveType)
        let path = try #require(bundle.path(forResource: fixture.filename, ofType: fixture.type))

        try sut.unarchive(filePath: URL(filePath: path), installationDestination: installationDestination)

        let fileManager = FileManager.default
        #expect(fileManager.fileExists(atPath: installationDestination.path))
        #expect(fileManager.fileExists(atPath: installationDestination.appending(component: "MockContent.txt").path))
    }

    @Test
    func unarchive_unrecognizedFileType_throws() throws {
        let unarchiverFileManager = UnarchiverFileManagerMock(fileManager: .default)
        let fileTypeDetectorFileManager = FileTypeDetectorFileManagerMock(fileManager: .default)
        let fileTypeDetector = FileTypeDetector(fileManager: fileTypeDetectorFileManager)
        let sut = Unarchiver(fileManager: unarchiverFileManager, fileTypeDetector: fileTypeDetector)

        // Create a file with unknown magic bytes and no known extension
        let tempURL = FileManager.default.temporaryDirectory
            .appending(component: "UnarchiverTests-\(UUID().uuidString).unknown")
        _ = FileManager.default.createFile(atPath: tempURL.path, contents: Data([0x01, 0x02, 0x03, 0x04]))
        defer { try? FileManager.default.removeItem(at: tempURL) }

        let installationDestination = unarchiverFileManager.toolsFolder
            .appending(components: "Tool", "1.0.0")

        #expect {
            try sut.unarchive(filePath: tempURL, installationDestination: installationDestination)
        } throws: { error in
            guard let unarchiverError = error as? Unarchiver.UnarchiverError,
                  case .unrecognizedFileType = unarchiverError else { return false }
            return true
        }
    }

    @Test
    func unarchive_notAnArchive_throws() throws {
        let unarchiverFileManager = UnarchiverFileManagerMock(fileManager: .default)
        let fileTypeDetectorFileManager = FileTypeDetectorFileManagerMock(fileManager: .default)
        let fileTypeDetector = FileTypeDetector(fileManager: fileTypeDetectorFileManager)
        let sut = Unarchiver(fileManager: unarchiverFileManager, fileTypeDetector: fileTypeDetector)

        // Create a file with Mach-O 64-bit magic bytes (detected as executable)
        let machoData = Data([0xFE, 0xED, 0xFA, 0xCF] + Array(repeating: 0x00, count: 12))
        let tempURL = FileManager.default.temporaryDirectory
            .appending(component: "UnarchiverTests-\(UUID().uuidString)")
        _ = FileManager.default.createFile(atPath: tempURL.path, contents: machoData)
        defer { try? FileManager.default.removeItem(at: tempURL) }

        let installationDestination = unarchiverFileManager.toolsFolder
            .appending(components: "Tool", "1.0.0")

        #expect {
            try sut.unarchive(filePath: tempURL, installationDestination: installationDestination)
        } throws: { error in
            guard let unarchiverError = error as? Unarchiver.UnarchiverError,
                  case .notAnArchive = unarchiverError else { return false }
            return true
        }
    }

    @Test
    func unarchive_failedToUnarchive_throws() throws {
        let unarchiverFileManager = UnarchiverFileManagerMock(fileManager: .default)
        let fileTypeDetectorFileManager = FileTypeDetectorFileManagerMock(fileManager: .default)
        let fileTypeDetector = FileTypeDetector(fileManager: fileTypeDetectorFileManager)
        let sut = Unarchiver(fileManager: unarchiverFileManager, fileTypeDetector: fileTypeDetector)

        // Create a corrupt zip file (has ZIP magic bytes but corrupt content)
        let corruptZipData = Data([0x50, 0x4B, 0x00, 0x00] + Array(repeating: 0xFF, count: 100))
        let tempURL = FileManager.default.temporaryDirectory
            .appending(component: "UnarchiverTests-\(UUID().uuidString).zip")
        _ = FileManager.default.createFile(atPath: tempURL.path, contents: corruptZipData)
        defer { try? FileManager.default.removeItem(at: tempURL) }

        let installationDestination = unarchiverFileManager.toolsFolder
            .appending(components: "Tool", "1.0.0")

        #expect {
            try sut.unarchive(filePath: tempURL, installationDestination: installationDestination)
        } throws: { error in
            guard let unarchiverError = error as? Unarchiver.UnarchiverError,
                  case .failedToUnarchive = unarchiverError else { return false }
            return true
        }
    }
}
