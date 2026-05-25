//  FileTypeDetectorTests.swift

import Foundation
import Testing
@testable import LucaCore
@testable import ManagerCore

struct FileTypeDetectorTests {

    private let fileManager = FileManager.default

    private func writeTempFile(data: Data, name: String) throws -> URL {
        let url = fileManager.temporaryDirectory.appending(component: "FileTypeDetectorTests-\(UUID().uuidString)-\(name)")
        _ = fileManager.createFile(atPath: url.path, contents: data)
        return url
    }

    @Test
    func test_detectFileType_zip_byMagicBytes() throws {
        let fileTypeDetectorFileManager = FileTypeDetectorFileManagerMock(fileManager: .default)
        let sut = FileTypeDetector(fileManager: fileTypeDetectorFileManager)

        let data = Data([0x50, 0x4B, 0x00, 0x00])
        let url = try writeTempFile(data: data, name: "archive.bin")
        defer { try? fileManager.removeItem(at: url) }

        let result = try sut.detectFileType(at: url)

        #expect(result == .zip)
    }

    @Test
    func test_detectFileType_targz_byMagicBytes() throws {
        let fileTypeDetectorFileManager = FileTypeDetectorFileManagerMock(fileManager: .default)
        let sut = FileTypeDetector(fileManager: fileTypeDetectorFileManager)

        let data = Data([0x1F, 0x8B, 0x00, 0x00])
        let url = try writeTempFile(data: data, name: "archive.bin")
        defer { try? fileManager.removeItem(at: url) }

        let result = try sut.detectFileType(at: url)

        #expect(result == .targz)
    }

    @Test
    func test_detectFileType_machoExecutable_32bit() throws {
        let fileTypeDetectorFileManager = FileTypeDetectorFileManagerMock(fileManager: .default)
        let sut = FileTypeDetector(fileManager: fileTypeDetectorFileManager)

        let data = Data([0xFE, 0xED, 0xFA, 0xCE] + Array(repeating: 0x00, count: 12))
        let url = try writeTempFile(data: data, name: "binary")
        defer { try? fileManager.removeItem(at: url) }

        let result = try sut.detectFileType(at: url)

        #expect(result == .executable)
    }

    @Test
    func test_detectFileType_machoExecutable_64bit() throws {
        let fileTypeDetectorFileManager = FileTypeDetectorFileManagerMock(fileManager: .default)
        let sut = FileTypeDetector(fileManager: fileTypeDetectorFileManager)

        let data = Data([0xFE, 0xED, 0xFA, 0xCF] + Array(repeating: 0x00, count: 12))
        let url = try writeTempFile(data: data, name: "binary")
        defer { try? fileManager.removeItem(at: url) }

        let result = try sut.detectFileType(at: url)

        #expect(result == .executable)
    }

    @Test
    func test_detectFileType_machoExecutable_64bitReversed() throws {
        let fileTypeDetectorFileManager = FileTypeDetectorFileManagerMock(fileManager: .default)
        let sut = FileTypeDetector(fileManager: fileTypeDetectorFileManager)

        let data = Data([0xCF, 0xFA, 0xED, 0xFE] + Array(repeating: 0x00, count: 12))
        let url = try writeTempFile(data: data, name: "binary")
        defer { try? fileManager.removeItem(at: url) }

        let result = try sut.detectFileType(at: url)

        #expect(result == .executable)
    }

    @Test
    func test_detectFileType_elfExecutable() throws {
        let fileTypeDetectorFileManager = FileTypeDetectorFileManagerMock(fileManager: .default)
        let sut = FileTypeDetector(fileManager: fileTypeDetectorFileManager)

        let data = Data([0x7F, 0x45, 0x4C, 0x46] + Array(repeating: 0x00, count: 12))
        let url = try writeTempFile(data: data, name: "binary")
        defer { try? fileManager.removeItem(at: url) }

        let result = try sut.detectFileType(at: url)

        #expect(result == .executable)
    }

    @Test
    func test_detectFileType_unknownBytes_returnsNil() throws {
        let fileTypeDetectorFileManager = FileTypeDetectorFileManagerMock(fileManager: .default)
        let sut = FileTypeDetector(fileManager: fileTypeDetectorFileManager)

        let data = Data([0x01, 0x02, 0x03, 0x04] + Array(repeating: 0x00, count: 12))
        let url = try writeTempFile(data: data, name: "unknown.bin")
        defer { try? fileManager.removeItem(at: url) }

        let result = try sut.detectFileType(at: url)

        #expect(result == nil)
    }

    @Test
    func test_detectFileType_zipExtensionFallback() throws {
        let fileTypeDetectorFileManager = FileTypeDetectorFileManagerMock(fileManager: .default)
        let sut = FileTypeDetector(fileManager: fileTypeDetectorFileManager)

        let data = Data([0x01, 0x02, 0x03, 0x04] + Array(repeating: 0x00, count: 12))
        let url = try writeTempFile(data: data, name: "archive.zip")
        defer { try? fileManager.removeItem(at: url) }

        let result = try sut.detectFileType(at: url)

        #expect(result == .zip)
    }

    @Test
    func test_detectFileType_gzExtensionFallback() throws {
        let fileTypeDetectorFileManager = FileTypeDetectorFileManagerMock(fileManager: .default)
        let sut = FileTypeDetector(fileManager: fileTypeDetectorFileManager)

        let data = Data([0x01, 0x02, 0x03, 0x04] + Array(repeating: 0x00, count: 12))
        let url = try writeTempFile(data: data, name: "archive.gz")
        defer { try? fileManager.removeItem(at: url) }

        let result = try sut.detectFileType(at: url)

        #expect(result == .targz)
    }

    @Test
    func test_detectFileType_peExecutable() throws {
        let fileTypeDetectorFileManager = FileTypeDetectorFileManagerMock(fileManager: .default)
        let sut = FileTypeDetector(fileManager: fileTypeDetectorFileManager)

        let data = Data([0x4D, 0x5A] + Array(repeating: 0x00, count: 14))
        let url = try writeTempFile(data: data, name: "tool.exe")
        defer { try? fileManager.removeItem(at: url) }

        let result = try sut.detectFileType(at: url)

        #expect(result == .executable)
    }

    @Test
    func test_detectFileType_machoExecutable_32bitReversed() throws {
        let fileTypeDetectorFileManager = FileTypeDetectorFileManagerMock(fileManager: .default)
        let sut = FileTypeDetector(fileManager: fileTypeDetectorFileManager)

        let data = Data([0xCE, 0xFA, 0xED, 0xFE] + Array(repeating: 0x00, count: 12))
        let url = try writeTempFile(data: data, name: "binary")
        defer { try? fileManager.removeItem(at: url) }

        let result = try sut.detectFileType(at: url)

        #expect(result == .executable)
    }
}
