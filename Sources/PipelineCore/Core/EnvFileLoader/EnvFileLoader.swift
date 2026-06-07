//  EnvFileLoader.swift

import Foundation
import Yams

/// Loads and parses flat YAML env-var files.
///
/// The expected file format is a flat mapping of string keys to string values:
///
/// ```yaml
/// API_KEY: secret123
/// ENVIRONMENT: staging
/// DEBUG: "true"
/// ```
///
/// Nested mappings or non-string values are rejected with ``EnvFileLoaderError/invalidFormat``.
public struct EnvFileLoader: EnvFileLoading {

    public enum EnvFileLoaderError: Error, LocalizedError, Equatable {
        /// The file at the specified URL does not exist or could not be read.
        case fileNotFound(URL)
        /// The YAML content is not a flat `[String: String]` mapping.
        case invalidFormat

        public var errorDescription: String? {
            switch self {
            case .fileNotFound(let url):
                return "Env file not found at path: \(url.path)"
            case .invalidFormat:
                return "Env file must contain a flat mapping of string keys to string values."
            }
        }
    }

    public init() {}

    // MARK: - EnvFileLoading

    /// Loads environment variables from the specified YAML file.
    ///
    /// - Parameter url: URL to the flat YAML file containing string key-value pairs.
    /// - Returns: A dictionary of environment variable names to their string values.
    /// - Throws: ``EnvFileLoaderError/fileNotFound(_:)`` if the file does not exist,
    ///   or ``EnvFileLoaderError/invalidFormat`` if the YAML is not a flat `[String: String]` mapping.
    public func load(from url: URL) throws -> [String: String] {
        let data: Data
        do {
            data = try Data(contentsOf: url)
        } catch {
            throw EnvFileLoaderError.fileNotFound(url)
        }

        guard let yamlString = String(data: data, encoding: .utf8) else {
            throw EnvFileLoaderError.invalidFormat
        }

        // Yams.load returns Any? — nil means empty/null YAML, which is a valid empty env file.
        let rawNode: Any?
        do {
            rawNode = try Yams.load(yaml: yamlString)
        } catch {
            throw EnvFileLoaderError.invalidFormat
        }

        // Empty file or explicit null YAML node — treat as empty dict.
        guard let rawNode else {
            return [:]
        }

        guard let rawDict = rawNode as? [String: Any] else {
            throw EnvFileLoaderError.invalidFormat
        }

        var result: [String: String] = [:]
        for (key, value) in rawDict {
            guard let stringValue = value as? String else {
                throw EnvFileLoaderError.invalidFormat
            }
            result[key] = stringValue
        }
        return result
    }
}
