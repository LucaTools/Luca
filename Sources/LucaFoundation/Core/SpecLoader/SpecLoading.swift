//  SpecLoading.swift

import Foundation

/// Reads and decodes a Lucafile from disk.
public protocol SpecLoading {
    /// Loads and decodes the spec file at the given path.
    /// - Parameter path: The URL of the Lucafile (YAML).
    /// - Returns: A decoded ``Spec`` containing the tool definitions.
    func loadSpec(at path: URL) throws -> Spec
}
