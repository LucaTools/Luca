//  SelfUpdaterFileManagerMock.swift

import Foundation
@testable import LucaCore

class SelfUpdaterFileManagerMock: SelfUpdaterFileManaging, @unchecked Sendable {

    /// Stubs the current working directory path.
    var stubbedCurrentDirectoryPath: String = FileManager.default.temporaryDirectory
        .appendingPathComponent(UUID().uuidString).path

    /// Controls the content of `.luca-version`. `nil` means the file is absent.
    var stubbedVersionFileContent: String?

    /// Controls whether the install destination is considered writable.
    var stubbedIsWritable: Bool = true

    private(set) var movedItems: [(src: URL, dst: URL)] = []
    private(set) var setAttributesCalls: [(path: String, attributes: [FileAttributeKey: Any])] = []
    private(set) var createdDirectories: [URL] = []
    private(set) var removedItems: [URL] = []

    var currentDirectoryPath: String { stubbedCurrentDirectoryPath }

    func fileExists(atPath path: String) -> Bool {
        if path.hasSuffix(".luca-version") {
            return stubbedVersionFileContent != nil
        }
        return true
    }

    func contentsOfFile(atPath path: String) -> String? {
        if path.hasSuffix(".luca-version") {
            return stubbedVersionFileContent
        }
        return nil
    }

    func isWritableFile(atPath path: String) -> Bool { stubbedIsWritable }

    func createDirectory(at url: URL, withIntermediateDirectories: Bool) throws {
        createdDirectories.append(url)
    }

    func removeItem(at url: URL) throws {
        removedItems.append(url)
    }

    func moveItem(at srcURL: URL, to dstURL: URL) throws {
        movedItems.append((src: srcURL, dst: dstURL))
    }

    func setAttributes(_ attributes: [FileAttributeKey: Any], ofItemAtPath path: String) throws {
        setAttributesCalls.append((path: path, attributes: attributes))
    }
}
