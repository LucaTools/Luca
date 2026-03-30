//  GitHubSkillTreeFetching.swift

import Foundation

/// Fetches the list of skill paths from a GitHub repository's file tree, and downloads individual skill files.
protocol GitHubSkillTreeFetching {
    /// Returns the paths of all `SKILL.md` blob items in the repository tree.
    ///
    /// - Parameters:
    ///   - owner: The GitHub repository owner (user or organisation).
    ///   - repo: The repository name.
    /// - Returns: An array of file paths whose last component is `SKILL.md`.
    func skillPaths(owner: String, repo: String) async throws -> [String]

    /// Downloads the raw content of a skill file.
    ///
    /// - Parameters:
    ///   - owner: The GitHub repository owner.
    ///   - repo: The repository name.
    ///   - path: The repository-relative path to the skill file.
    /// - Returns: The raw file data.
    func downloadSkill(owner: String, repo: String, path: String) async throws -> Data
}
