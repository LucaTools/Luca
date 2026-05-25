//  SpecInitializerFileManaging.swift

import Foundation

/// File system interface for ``SpecInitializer``.
public protocol SpecInitializerFileManaging {
    var homeDirectoryForCurrentUser: URL { get }
    var currentDirectoryPath: String { get }
    func fileExists(atPath path: String) -> Bool
    func createDirectory(at url: URL, withIntermediateDirectories: Bool) throws
    func writeString(_ content: String, to url: URL) throws
}
