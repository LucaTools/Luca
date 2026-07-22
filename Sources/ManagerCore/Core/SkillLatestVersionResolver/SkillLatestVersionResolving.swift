//  SkillLatestVersionResolving.swift

import Foundation

/// Resolves the `latest` version sentinel for a skill repository to a concrete commit SHA.
protocol SkillLatestVersionResolving: Sendable {
    /// Returns the current commit SHA of `repository`'s default branch HEAD.
    /// - Parameter repository: The repository reference — an SSH URL, an HTTPS URL, or an `owner/repo` GitHub shorthand.
    func resolveLatestVersion(repository: String) async throws -> String
}
