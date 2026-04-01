//  SkillRepositoryFetching.swift

import Foundation

/// Fetches the list of skill paths and their file contents from a repository.
protocol SkillRepositoryFetching {
    /// Returns the paths of all skill-related blobs in the repository.
    ///
    /// A path is included when it is either a `SKILL.md` file or any other blob that lives
    /// inside a directory that contains a `SKILL.md`. This ensures auxiliary files such as
    /// `resources/` are returned alongside `SKILL.md`.
    ///
    /// - Parameter repository: The repository reference — an SSH URL, an HTTPS URL, or an
    ///   `owner/repo` GitHub shorthand.
    /// - Returns: An array of repository-relative file paths for every skill-related blob.
    func skillPaths(repository: String) async throws -> [String]

    /// Returns the raw content of a skill file from the repository.
    ///
    /// - Parameters:
    ///   - repository: The repository reference.
    ///   - path: The repository-relative path to the skill file.
    /// - Returns: The raw file data.
    func downloadSkill(repository: String, path: String) async throws -> Data
}
