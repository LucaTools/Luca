//  SpecFinding.swift

import Foundation

public protocol SpecFinding {
    /// Finds all files with the `Lucafile` prefix in the given directory.
    /// - Parameter directory: The directory URL to search in.
    /// - Returns: An array of URLs for matching Lucafile-prefixed files, sorted alphabetically.
    func findSpecFiles(in directory: URL) throws -> [URL]
}
