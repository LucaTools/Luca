//  ParamsFileLoader.swift

import Foundation
import Yams

/// Loads and parses pipeline parameter YAML files.
///
/// The expected file format is a `params:` list of key/value objects:
///
/// ```yaml
/// params:
///   - key: environment
///     value: staging
///   - key: upload
///     value: "true"
/// ```
public struct ParamsFileLoader: ParamsFileLoading {

    public enum ParamsFileLoaderError: Error, LocalizedError, Equatable {
        /// The file at the specified URL does not exist or could not be read.
        case fileNotFound(URL)
        /// The file is not valid UTF-8 or does not conform to the expected YAML structure.
        case invalidFormat

        public var errorDescription: String? {
            switch self {
            case .fileNotFound(let url):
                return "Params file not found at path: \(url.path)"
            case .invalidFormat:
                return "Params file must contain a `params:` list of `{key, value}` pairs."
            }
        }
    }

    private struct ParamsFile: Codable {
        let params: [ParamEntry]

        struct ParamEntry: Codable {
            let key: String
            let value: String
        }
    }

    private let fileManager: any ParamsFileLoaderFileManaging

    public init(fileManager: any ParamsFileLoaderFileManaging = FileManager.default) {
        self.fileManager = fileManager
    }

    // MARK: - ParamsFileLoading

    /// Loads parameters from the specified YAML params file.
    ///
    /// - Parameter url: URL to a YAML file containing a `params:` list of key/value pairs.
    /// - Returns: A dictionary of parameter names to their string values.
    /// - Throws: ``ParamsFileLoaderError/fileNotFound(_:)`` if the file does not exist,
    ///   or ``ParamsFileLoaderError/invalidFormat`` if the YAML is malformed or not valid UTF-8.
    public func load(from url: URL) throws -> [String: String] {
        guard let data = fileManager.contents(atPath: url.path) else {
            throw ParamsFileLoaderError.fileNotFound(url)
        }

        guard let content = String(data: data, encoding: .utf8) else {
            throw ParamsFileLoaderError.invalidFormat
        }

        let paramsFile: ParamsFile
        do {
            paramsFile = try YAMLDecoder().decode(ParamsFile.self, from: content)
        } catch {
            throw ParamsFileLoaderError.invalidFormat
        }

        return paramsFile.params.reduce(into: [:]) { dict, entry in
            dict[entry.key] = entry.value
        }
    }
}
