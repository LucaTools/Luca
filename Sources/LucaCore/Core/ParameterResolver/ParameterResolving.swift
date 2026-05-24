//  ParameterResolving.swift

/// Validates and resolves pipeline parameter declarations against caller-supplied values.
public protocol ParameterResolving {
    /// Merges declared parameter definitions with caller-supplied values.
    ///
    /// - Parameters:
    ///   - declared: Parameter definitions from the pipeline YAML.
    ///   - provided: Key-value pairs supplied via `--param` on the CLI.
    /// - Returns: Resolved `[name: value]` map ready for command substitution.
    /// - Throws: If a provided key is not declared, or if a required parameter has no value.
    func resolve(declared: [PipelineParameter], provided: [String: String]) throws -> [String: String]
}
