//  GlobalSpecFinderFileManaging.swift

import Foundation

/// File system interface for ``GlobalSpecFinder``.
public protocol GlobalSpecFinderFileManaging {
    var homeDirectoryForCurrentUser: URL { get }
    func fileExists(atPath path: String) -> Bool
    func createDirectory(at url: URL, withIntermediateDirectories createIntermediates: Bool) throws
}
