//  GitRepositoryURLNormalizer.swift

import Foundation

/// Normalizes a repository reference into a URL string usable by `git` subcommands.
enum GitRepositoryURLNormalizer {
    /// Returns a git-clonable URL for the given repository reference.
    ///
    /// SSH and HTTPS/HTTP URLs are passed through unchanged; `owner/repo` shorthand is
    /// expanded to `https://github.com/owner/repo`.
    static func cloneURL(for repository: String) -> String {
        if repository.hasPrefix("git@")
            || repository.hasPrefix("https://")
            || repository.hasPrefix("http://") {
            return repository
        }
        return "https://github.com/\(repository)"
    }
}
