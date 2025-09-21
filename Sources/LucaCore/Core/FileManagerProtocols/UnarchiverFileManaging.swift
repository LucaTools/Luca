//  UnarchiverFileManaging.swift

import Foundation

public protocol UnarchiverFileManaging {
    var toolsFolder: URL { get }
    var homeDirectoryForCurrentUser: URL { get }
    func createDirectory(at url: URL, withIntermediateDirectories: Bool) throws
}
