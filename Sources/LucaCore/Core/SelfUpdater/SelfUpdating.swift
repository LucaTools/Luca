//  SelfUpdating.swift

import Foundation

/// Checks for a newer CLI version and replaces the running binary in-place.
public protocol SelfUpdating {

    /// Performs a version check against `.luca-version` in the current directory
    /// and installs the required version if it differs from `currentVersion`.
    ///
    /// - Parameter currentVersion: The version string of the running binary.
    func updateIfNeeded(currentVersion: String) async throws

    /// Fetches the latest release from GitHub and installs it if it differs from `currentVersion`.
    ///
    /// - Parameter currentVersion: The version string of the running binary.
    func updateToLatest(currentVersion: String) async throws
}
