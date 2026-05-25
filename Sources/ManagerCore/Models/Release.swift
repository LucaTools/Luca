//  Release.swift

import Foundation

/// Identifies a GitHub release by its owner, repository, and version tag.
struct Release: Codable, Equatable {
    /// The GitHub organization or user that owns the repository.
    let organization: String
    /// The repository name.
    let repository: String
    /// The release version tag (e.g. `"1.2.3"` or `"v1.2.3"`).
    let version: String
}
