//  GlobalSpecFinder.swift

import Foundation
import LucaFoundation

/// Searches `~/.config/luca/` for the first recognised spec file.
///
/// Checks each name in ``Constants/specFiles`` (plain then `.yml`) in priority order.
public struct GlobalSpecFinder: GlobalSpecFinding {

    /// Errors thrown by ``GlobalSpecFinder``.
    public enum GlobalSpecFinderError: Error, LocalizedError, Equatable {
        /// No recognised spec file was found in the global config directory.
        case noSpecFound(String)

        public var errorDescription: String? {
            switch self {
            case .noSpecFound(let path):
                return "No global spec file found in \(path). Create a Lucafile, Toolfile, or Skillfile (optionally with .yml extension) to get started."
            }
        }
    }

    private let fileManager: GlobalSpecFinderFileManaging

    public init(fileManager: GlobalSpecFinderFileManaging) {
        self.fileManager = fileManager
    }

    /// Finds the first recognised global spec file in `~/.config/luca/`.
    ///
    /// - Returns: The URL of the first matching file.
    /// - Throws: ``GlobalSpecFinderError/noSpecFound(_:)`` if no spec file is found.
    public func findGlobalSpec() throws -> URL {
        let globalConfigDir = fileManager.homeDirectoryForCurrentUser
            .appending(components: ".config", "luca")
        try fileManager.createDirectory(at: globalConfigDir, withIntermediateDirectories: true)

        for name in Constants.specFiles {
            let plain = globalConfigDir.appending(component: name)
            if fileManager.fileExists(atPath: plain.path) {
                return plain
            }
            let yml = globalConfigDir.appending(component: "\(name).\(Constants.ymlExtension)")
            if fileManager.fileExists(atPath: yml.path) {
                return yml
            }
        }

        throw GlobalSpecFinderError.noSpecFound(globalConfigDir.path)
    }
}
