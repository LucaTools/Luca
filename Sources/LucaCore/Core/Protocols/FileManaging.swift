//  FileManaging.swift

import Foundation

// maybe this doesn't have to be matching Foudnation's FileManager

public protocol FileManaging {
    var homeDirectoryForCurrentUser: URL { get }
    var currentDirectoryPath: String { get }
    var temporaryDirectory: URL { get }
    func fileExists(atPath: String) -> Bool
    func removeItem(at: URL) throws
    func removeItem(atPath: String) throws
    func moveItem(at: URL, to: URL) throws
    func createDirectory(at url: URL, withIntermediateDirectories: Bool) throws
    func createSymbolicLink(at url: URL, withDestinationURL destinationURL: URL) throws
    func destinationOfSymbolicLink(atPath path: String) throws -> String
}
