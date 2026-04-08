//  SpecFinder.swift

import Foundation

/// Discovers spec files in a directory.
///
/// Scans for files whose name starts with a recognised prefix
/// (`Lucafile`, `Toolfile`, `Skillfile`) and their variants
/// (e.g. `Lucafile.yml`, `Toolfile-dev`, `Skillfile-production`).
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
            .filter { url in
                Constants.specFiles.contains { url.lastPathComponent.hasPrefix($0) }
            }
            .sorted { $0.lastPathComponent < $1.lastPathComponent }
    }
}
