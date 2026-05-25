//  SelfUpdaterFileManagerMock.swift

import Foundation
@testable import LucaFoundation
@testable import ManagerCore

class SelfUpdaterFileManagerMock: SelfUpdaterFileManaging, @unchecked Sendable {

    /// Stubs the current working directory path.
    var stubbedCurrentDirectoryPath: String = FileManager.default.temporaryDirectory
        .appendingPathComponent(UUID().uuidString).path

    /// Controls the content of `.luca-version`. `nil` means the file is absent.
    var stubbedVersionFileContent: String?

    /// Controls whether the install destination is considered writable.
    var stubbedIsWritable: Bool = true

    /// Controls whether binary candidates (luca/Luca) appear to exist in the extract directory.
    var stubbedBinaryExists: Bool = true

    /// When set, `moveItem` records the call then throws this error.
    var stubbedMoveItemError: Error?

    private(set) var movedItems: [(src: URL, dst: URL)] = []
    private(set) var setAttributesCalls: [(path: String, attributes: [FileAttributeKey: Any])] = []
    private(set) var createdDirectories: [URL] = []
    private(set) var removedItems: [URL] = []
    private(set) var writtenStrings: [(content: String, url: URL)] = []

    var currentDirectoryPath: String { stubbedCurrentDirectoryPath }

    var homeDirectoryForCurrentUser: URL {
        URL(fileURLWithPath: stubbedCurrentDirectoryPath).appendingPathComponent("home")
    }

    func fileExists(atPath path: String) -> Bool {
        if path.hasSuffix(".luca-version") {
            return stubbedVersionFileContent != nil
        }
        return stubbedBinaryExists
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
        if let error = stubbedMoveItemError {
            throw error
        }
    }

    func writeString(_ content: String, to url: URL) throws {
        writtenStrings.append((content: content, url: url))
    }

    func setAttributes(_ attributes: [FileAttributeKey: Any], ofItemAtPath path: String) throws {
        setAttributesCalls.append((path: path, attributes: attributes))
    }
}
