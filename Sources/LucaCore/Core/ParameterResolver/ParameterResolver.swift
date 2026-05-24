//  ParameterResolver.swift

import Foundation

/// Validates declared pipeline parameters and merges them with CLI-provided values.
///
/// Precedence: CLI `--param` value → YAML `default:` → error (required, not provided).
public struct ParameterResolver: ParameterResolving {

    public enum ParameterResolverError: Error, LocalizedError, Equatable {
        case unknownParameter(String)
        case missingRequiredParameter(String)

        public var errorDescription: String? {
            switch self {
            case .unknownParameter(let name):
                return "Unknown parameter '\(name)'. It is not declared in the pipeline's parameters block."
            case .missingRequiredParameter(let name):
                return "Required parameter '\(name)' was not provided. Pass it with --param \(name)=<value>."
            }
        }
    }

    public init() {}

    // MARK: - ParameterResolving

    public func resolve(declared: [PipelineParameter], provided: [String: String]) throws -> [String: String] {
        let declaredNames = Set(declared.map(\.name))
        for key in provided.keys {
            guard declaredNames.contains(key) else {
                throw ParameterResolverError.unknownParameter(key)
            }
        }
        var resolved: [String: String] = [:]
        for param in declared {
            if let value = provided[param.name] {
                resolved[param.name] = value
            } else if let defaultValue = param.defaultValue {
                resolved[param.name] = defaultValue
            } else {
                throw ParameterResolverError.missingRequiredParameter(param.name)
            }
        }
        return resolved
    }
}
