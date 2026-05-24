//  PipelineParameter.swift

import Foundation

/// A single declared input parameter for a ``Pipeline``.
///
/// Parameters are declared in the pipeline YAML and resolved against values
/// supplied via `--param` at invocation time. Use `${name}` in task commands
/// to reference the resolved value.
///
/// ## Example
///
/// ```yaml
/// parameters:
///   - name: flavor
///     description: Build flavor (debug or release)
///     default: debug
///   - name: upload
///     description: Whether to upload the artifact
/// ```
///
/// ## Topics
///
/// ### Properties
/// - ``name``
/// - ``description``
/// - ``defaultValue``
public struct PipelineParameter: Codable, Equatable {
    /// Key used in `${name}` substitutions and `--param name=value` on the CLI.
    public let name: String
    /// Optional human-readable description shown in `--dry-run` output.
    public let description: String?
    /// Value used when no `--param` override is supplied. A `nil` default means the parameter is required.
    public let defaultValue: String?

    public init(name: String, description: String? = nil, defaultValue: String? = nil) {
        self.name = name
        self.description = description
        self.defaultValue = defaultValue
    }

    private enum CodingKeys: String, CodingKey {
        case name, description
        case defaultValue = "default"
    }
}
