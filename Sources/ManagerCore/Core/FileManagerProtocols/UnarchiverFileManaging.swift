//  UnarchiverFileManaging.swift

import Foundation

/// File system interface for ``Unarchiver``.
public protocol UnarchiverFileManaging {
    var toolsFolder: URL { get }
    var homeDirectoryForCurrentUser: URL { get }
    func createDirectory(at url: URL, withIntermediateDirectories: Bool) throws
}
