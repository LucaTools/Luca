//  SpecFinder.swift

import Foundation

/// Discovers Lucafile spec files in a directory.
///
/// Scans for files whose name starts with the `Lucafile` prefix
/// (e.g. `Lucafile`, `Lucafile.yml`, `Lucafile-dev`, `Lucafile-production`).
public struct SpecFinder: SpecFinding {

    private let fileManager: SpecFinderFileManaging

    public init(fileManager: SpecFinderFileManaging) {
        self.fileManager = fileManager
    }

    public func findSpecFiles(in directory: URL) throws -> [URL] {
        let contents = try fileManager.contentsOfDirectory(
            at: directory,
            includingPropertiesForKeys: nil,
            options: .skipsHiddenFiles
        )
        return contents
            .filter { $0.lastPathComponent.hasPrefix(Constants.specFile) }
            .sorted { $0.lastPathComponent < $1.lastPathComponent }
    }
}
