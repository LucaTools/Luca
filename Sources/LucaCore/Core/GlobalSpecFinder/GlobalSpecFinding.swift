//  GlobalSpecFinding.swift

import Foundation

/// Finds a global spec file in the Luca config directory.
protocol GlobalSpecFinding {
    /// Finds the first recognised global spec file in `~/.config/luca/`.
    ///
    /// - Returns: The URL of the first found spec file.
    /// - Throws: ``GlobalSpecFinder/GlobalSpecFinderError/noSpecFound(_:)`` when no spec file exists.
    func findGlobalSpec() throws -> URL
}
