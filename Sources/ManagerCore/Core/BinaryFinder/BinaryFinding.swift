//  BinaryFinding.swift

import Foundation

/// Locates an executable binary within a directory tree.
protocol BinaryFinding {
    /// Searches the directory tree at `path` and returns the relative path of the first executable binary.
    /// - Parameter path: The root directory to search.
    /// - Returns: A relative path to the binary within the directory.
    func findBinary(atPath path: String) throws -> String
}
