//  PipelineLoader.swift

import Foundation
import Yams

/// Loads and parses pipeline YAML files.
///
/// ## Pipeline File Format
///
/// ```yaml
/// ---
/// env:
///   CI: "true"
///
/// tasks:
///   - name: Generate project
///     command: tuist generate
///   - name: Run tests
///     command: swift test
///     continue-on-error: true
/// ```
///
/// ## Topics
///
/// ### Loading Pipelines
/// - ``loadPipeline(at:)``
///
/// ### Related Types
/// - ``Pipeline``
/// - ``PipelineTask``
public struct PipelineLoader: PipelineLoading {

    public enum PipelineLoaderError: Error, LocalizedError, Equatable {
        case missingPipeline(String)
        case invalidPipeline(String, String)

        public var errorDescription: String? {
            switch self {
            case .missingPipeline(let path):
                return "Missing pipeline at path: \(path)"
            case .invalidPipeline(let path, let reason):
                return "Invalid pipeline at path: \(path). \(reason)"
            }
        }
    }

    private let fileManager: FileManager

    public init(fileManager: FileManager = .default) {
        self.fileManager = fileManager
    }

    // MARK: - PipelineLoading

    /// Loads a pipeline from the specified file path.
    ///
    /// - Parameter path: URL to the pipeline YAML file.
    /// - Returns: A ``Pipeline`` containing the parsed task definitions.
    /// - Throws: ``PipelineLoaderError/missingPipeline(_:)`` if the file doesn't exist,
    ///   or ``PipelineLoaderError/invalidPipeline(_:_:)`` if the YAML is malformed.
    public func loadPipeline(at path: URL) throws -> Pipeline {
        guard let data = fileManager.contents(atPath: path.path) else {
            throw PipelineLoaderError.missingPipeline(path.path)
        }
        do {
            return try YAMLDecoder().decode(Pipeline.self, from: data)
        } catch {
            throw PipelineLoaderError.invalidPipeline(path.path, Self.formattedParseError(error))
        }
    }
}

// MARK: - Helpers

extension PipelineLoader {

    static func formattedParseError(_ error: Error) -> String {
        if let decodingError = error as? DecodingError {
            switch decodingError {
            case .typeMismatch(_, let context):
                return formattedContext(context, prefix: "Type mismatch")
            case .valueNotFound(_, let context):
                return formattedContext(context, prefix: "Value not found")
            case .keyNotFound(let key, let context):
                return formattedContext(context, prefix: "Missing required key '\(key.stringValue)'")
            case .dataCorrupted(let context):
                return formattedContext(context, prefix: "Data corrupted")
            @unknown default: break
            }
        }
        return error.localizedDescription
    }

    private static func formattedContext(_ context: DecodingError.Context, prefix: String) -> String {
        let path = codingPath(from: context.codingPath)
        return path.isEmpty ? "\(prefix): \(context.debugDescription)" : "\(prefix) at '\(path)': \(context.debugDescription)"
    }

    private static func codingPath(from keys: [CodingKey]) -> String {
        var result = ""
        for key in keys {
            if let index = key.intValue {
                result += "[\(index)]"
            } else {
                if !result.isEmpty { result += "." }
                result += key.stringValue
            }
        }
        return result
    }
}
