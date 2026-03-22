//  SpecLoader.swift

import Foundation
import Yams

/// Loads and parses Lucafile specifications.
///
/// The `SpecLoader` reads YAML-formatted Lucafiles and converts them into
/// ``Spec`` objects that define the tools required for a project.
///
/// ## Lucafile Format
///
/// A Lucafile is a YAML file with the following structure:
///
/// ```yaml
/// ---
/// tools:
///   - name: SwiftLint
///     version: 0.61.0
///     url: https://github.com/realm/SwiftLint/releases/...
///     binaryPath: bin/swiftlint
/// ```
///
/// ## Topics
///
/// ### Loading Specs
/// - ``loadSpec(at:)``
///
/// ### Related Types
/// - ``Spec``
/// - ``Tool``
// MARK: - Helpers

private func formattedParseError(_ error: Error) -> String {
    guard let decodingError = error as? DecodingError else {
        return error.localizedDescription
    }
    switch decodingError {
    case .typeMismatch(_, let context):
        return formattedContext(context, prefix: "Type mismatch")
    case .valueNotFound(_, let context):
        return formattedContext(context, prefix: "Value not found")
    case .keyNotFound(let key, let context):
        return formattedContext(context, prefix: "Missing required key '\(key.stringValue)'")
    case .dataCorrupted(let context):
        return formattedContext(context, prefix: "Data corrupted")
    @unknown default:
        return decodingError.localizedDescription
    }
}

private func formattedContext(_ context: DecodingError.Context, prefix: String) -> String {
    let path = codingPath(from: context.codingPath)
    return path.isEmpty ? "\(prefix): \(context.debugDescription)" : "\(prefix) at '\(path)': \(context.debugDescription)"
}

private func codingPath(from keys: [CodingKey]) -> String {
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

struct SpecLoader: SpecLoading {

    enum SpecLoaderError: Error, LocalizedError {
        case missingSpec(String)
        case invalidSpec(String, Error)

        var errorDescription: String? {
            switch self {
            case .missingSpec(let path):
                return "Missing spec at path: \(path)"
            case .invalidSpec(let path, let error):
                return "Invalid spec at path: \(path). \(formattedParseError(error))"
            }
        }
    }
    
    private let fileManager: FileManager
    
    init(fileManager: FileManager) {
        self.fileManager = fileManager
    }
    
    /// Loads a spec from the specified file path.
    ///
    /// - Parameter path: The URL to the Lucafile.
    /// - Returns: A ``Spec`` containing the parsed tool definitions.
    /// - Throws: ``SpecLoaderError/missingSpec(_:)`` if the file doesn't exist,
    ///   or ``SpecLoaderError/invalidSpec(_:_:)`` if the YAML is malformed.
    func loadSpec(at path: URL) throws -> Spec {
        guard let data = fileManager.contents(atPath: path.path) else {
            throw SpecLoaderError.missingSpec(path.path)
        }
        do {
            return try YAMLDecoder().decode(Spec.self, from: data)
        } catch {
            throw SpecLoaderError.invalidSpec(path.path, error)
        }
    }
}
