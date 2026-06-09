//  ParamsFileLoading.swift

import Foundation

/// Loads pipeline parameters from a YAML params file.
public protocol ParamsFileLoading {
    /// Loads parameters from the specified YAML params file.
    ///
    /// - Parameter url: URL to a YAML file containing a `params:` list of key/value pairs.
    /// - Returns: A dictionary of parameter names to their string values.
    func load(from url: URL) throws -> [String: String]
}
