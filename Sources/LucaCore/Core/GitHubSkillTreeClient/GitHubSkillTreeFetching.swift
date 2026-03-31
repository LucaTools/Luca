//  GitHubSkillTreeFetching.swift

import Foundation

/// Fetches the list of skill paths from a GitHub repository's file tree, and downloads individual skill files.
protocol GitHubSkillTreeFetching {
    /// Returns the paths of all skill-related blobs in the repository tree.
    ///
    /// A path is included when it is either a `SKILL.md` file or any other blob that lives
    /// inside a directory that contains a `SKILL.md` (i.e. a skill's root directory). This
    /// ensures auxiliary files such as `resources/` are returned alongside `SKILL.md`.
    ///
    /// - Parameters:
    ///   - owner: The GitHub repository owner (user or organisation).
    ///   - repo: The repository name.
    /// - Returns: An array of repository-relative file paths for every skill-related blob.
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
