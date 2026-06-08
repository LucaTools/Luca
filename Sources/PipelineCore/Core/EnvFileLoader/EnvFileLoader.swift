//  EnvFileLoader.swift

import Foundation

/// Loads and parses dotenv-style env-var files.
///
/// The expected file format is one `KEY=VALUE` pair per line:
///
/// ```
/// API_KEY=secret123
/// ENVIRONMENT=staging
/// DEBUG=true
/// PORT="8080"
/// # This is a comment
/// ```
///
/// Lines starting with `#` and blank lines are ignored. Surrounding single or double
/// quotes on values are stripped. Any non-blank, non-comment line without `=` is
/// rejected with ``EnvFileLoaderError/invalidFormat``.
public struct EnvFileLoader: EnvFileLoading {

    public enum EnvFileLoaderError: Error, LocalizedError, Equatable {
        /// The file at the specified URL does not exist or could not be read.
        case fileNotFound(URL)
        /// The file contains a line that is not a valid `KEY=VALUE` pair.
        case invalidFormat

        public var errorDescription: String? {
            switch self {
            case .fileNotFound(let url):
                return "Env file not found at path: \(url.path)"
            case .invalidFormat:
                return "Env file must contain KEY=VALUE pairs, one per line. Lines starting with # are treated as comments."
            }
        }
    }

    private let fileManager: any EnvFileLoaderFileManaging

    public init(fileManager: any EnvFileLoaderFileManaging = FileManager.default) {
        self.fileManager = fileManager
    }

    // MARK: - EnvFileLoading

    /// Loads environment variables from the specified dotenv file.
    ///
    /// - Parameter url: URL to a dotenv-style file with `KEY=VALUE` pairs.
    /// - Returns: A dictionary of environment variable names to their string values.
    /// - Throws: ``EnvFileLoaderError/fileNotFound(_:)`` if the file does not exist,
    ///   or ``EnvFileLoaderError/invalidFormat`` if any non-blank, non-comment line lacks `=`.
    public func load(from url: URL) throws -> [String: String] {
        guard let data = fileManager.contents(atPath: url.path) else {
            throw EnvFileLoaderError.fileNotFound(url)
        }

        guard let content = String(data: data, encoding: .utf8) else {
            throw EnvFileLoaderError.invalidFormat
        }

        var result: [String: String] = [:]
        for line in content.components(separatedBy: .newlines) {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            guard !trimmed.isEmpty, !trimmed.hasPrefix("#") else { continue }

            guard let equalsIndex = trimmed.firstIndex(of: "=") else {
                throw EnvFileLoaderError.invalidFormat
            }

            let key = String(trimmed[trimmed.startIndex..<equalsIndex]).trimmingCharacters(in: .whitespaces)
            guard !key.isEmpty else { throw EnvFileLoaderError.invalidFormat }

            var value = String(trimmed[trimmed.index(after: equalsIndex)...])
            // Strip matching surrounding quotes.
            if (value.hasPrefix("\"") && value.hasSuffix("\"")) ||
               (value.hasPrefix("'") && value.hasSuffix("'")) {
                value = String(value.dropFirst().dropLast())
            }
            result[key] = value
        }
        return result
    }
}
