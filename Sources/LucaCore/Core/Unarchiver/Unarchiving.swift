//  Unarchiving.swift

import Foundation

/// Extracts an archive into an installation directory.
protocol Unarchiving {
    /// Extracts the archive at `filePath` into `installationDestination`.
    /// - Parameters:
    ///   - filePath: The local path of the archive file (`.zip` or `.tar.gz`).
    ///   - installationDestination: The directory into which the archive is extracted.
    func unarchive(filePath: URL, installationDestination: URL) throws
}
