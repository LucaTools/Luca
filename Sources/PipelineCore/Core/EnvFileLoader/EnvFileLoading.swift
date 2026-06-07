//  EnvFileLoading.swift

import Foundation

/// Loads environment variables from a flat YAML file.
public protocol EnvFileLoading {
    /// Loads environment variables from the specified YAML file.
    ///
    /// - Parameter url: URL to the flat YAML file containing string key-value pairs.
    /// - Returns: A dictionary of environment variable names to their string values.
    func load(from url: URL) throws -> [String: String]
}
