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
struct SpecLoader: SpecLoading {
    
    enum SpecLoaderError: Error, LocalizedError {
        case missingSpec(String)
        case invalidSpec(String, Error)
        
        var errorDescription: String? {
            switch self {
            case .missingSpec(let path):
                return "Missing spec at path: \(path)"
            case .invalidSpec(let path, let error):
                return "Invalid spec at path: \(path). \(error)"
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
            let nsError = NSError(
                domain: "io.github.luca.specLoader",
                code: 1,
                userInfo: [NSUnderlyingErrorKey: error]
            )
            throw SpecLoaderError.invalidSpec(path.path, nsError)
        }
    }
}
