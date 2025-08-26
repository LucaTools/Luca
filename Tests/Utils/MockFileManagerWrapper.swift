//  MockFileManagerWrapper.swift

import Foundation
@testable import LucaCore

struct MockFileManagerWrapper: FileManaging {
    
    let fileManager: Foundation.FileManager = .default

    public var homeDirectoryForCurrentUser: URL {
        fileManager.temporaryDirectory
            .appending(component: "home")
    }

    public var currentDirectoryPath: String {
        fileManager.temporaryDirectory
            .appending(component: "project").absoluteString
    }
    
    public var temporaryDirectory: URL {
        fileManager.temporaryDirectory
    }
    
    public func fileExists(atPath path: String) -> Bool {
        fileManager.fileExists(atPath: path)
    }
    
    public func removeItem(at path: URL) throws {
        try fileManager.removeItem(at: path)
    }
    
    public func removeItem(atPath path: String) throws {
        try fileManager.removeItem(atPath: path)
    }
    
    public func moveItem(at: URL, to: URL) throws {
        try fileManager.moveItem(at: at, to: to)
    }
    
    public func createDirectory(at url: URL, withIntermediateDirectories: Bool) throws {
        try fileManager.createDirectory(at: url, withIntermediateDirectories: withIntermediateDirectories)
    }
    
    public func createSymbolicLink(at url: URL, withDestinationURL destinationURL: URL) throws {
        try fileManager.createSymbolicLink(at: url, withDestinationURL: destinationURL)
    }
    
    public func destinationOfSymbolicLink(atPath path: String) throws -> String {
        try fileManager.destinationOfSymbolicLink(atPath: path)
    }
}
