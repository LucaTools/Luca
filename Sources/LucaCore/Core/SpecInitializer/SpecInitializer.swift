//  SpecInitializer.swift

import Foundation

/// Creates a new spec file on disk, pre-populated with a commented template.
public struct SpecInitializer {

    /// Where the spec file should be written.
    public enum Location {
        /// The current working directory.
        case local
        /// The global config directory (`~/.config/luca/`).
        case global
    }

    /// Errors thrown by ``SpecInitializer``.
    public enum SpecInitializerError: Error, LocalizedError, Equatable {
        case fileAlreadyExists(String)

        public var errorDescription: String? {
            switch self {
            case .fileAlreadyExists(let path):
                return "A spec file already exists at \(path)."
            }
        }
    }

    /// The default template written to every new spec file.
    public static let template = """
    ---
    repos:
    #   swift-testing: AvdLee/Swift-Testing-Agent-Skill

    tools:
    #   - name: SwiftLint
    #     version: 0.61.0
    #     url: https://github.com/realm/SwiftLint/releases/download/0.61.0/portable_swiftlint.zip

    skills:
    #   - name: swift-concurrency
    #     repository: AvdLee/Swift-Concurrency-Agent-Skill
    #   - name: swift-testing-expert
    #     repository: swift-testing
    #     version: 1.2.0
    """

    private let fileManager: SpecInitializerFileManaging

    public init(fileManager: SpecInitializerFileManaging) {
        self.fileManager = fileManager
    }

    /// Creates a new spec file and returns its URL.
    ///
    /// - Parameters:
    ///   - name: The filename (e.g. `"Lucafile"`).
    ///   - location: Where to write the file.
    ///   - overwrite: When `false` (default), throws ``SpecInitializerError/fileAlreadyExists(_:)`` if a file already exists at the target path.
    /// - Returns: The URL of the created file.
    @discardableResult
    public func createSpec(named name: String, location: Location, overwrite: Bool = false) throws -> URL {
        let directory: URL
        switch location {
        case .local:
            directory = URL(fileURLWithPath: fileManager.currentDirectoryPath)
        case .global:
            directory = fileManager.homeDirectoryForCurrentUser.appending(components: ".config", "luca")
        }

        let targetURL = directory.appending(component: name)

        if fileManager.fileExists(atPath: targetURL.path) && !overwrite {
            throw SpecInitializerError.fileAlreadyExists(targetURL.path)
        }

        try fileManager.createDirectory(at: directory, withIntermediateDirectories: true)
        try fileManager.writeString(Self.template, to: targetURL)

        return targetURL
    }
}
