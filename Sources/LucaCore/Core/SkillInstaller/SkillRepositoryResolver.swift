//  SkillRepositoryResolver.swift

import Foundation

/// Validates and resolves a skill repository reference.
///
/// `SkillRepositoryResolver` accepts either an `owner/repo` shorthand or a full
/// HTTPS URL and passes it through unchanged to `npx skills add`. It rejects
/// values that match neither form.
struct SkillRepositoryResolver {

    enum SkillRepositoryResolverError: Error, LocalizedError, Equatable {
        case invalidRepositoryFormat(String)

        var errorDescription: String? {
            switch self {
            case .invalidRepositoryFormat(let repository):
                return "Invalid repository format '\(repository)'. Expected 'owner/repo' or a full HTTPS URL."
            }
        }
    }

    /// Validates and returns the repository reference as-is if it is well-formed.
    ///
    /// - Parameter repository: Either `owner/repo` or a full HTTPS URL.
    /// - Returns: The validated repository reference, ready to pass to `npx skills add`.
    func resolve(_ repository: String) throws -> String {
        // Accept full HTTPS URLs
        if repository.hasPrefix("https://") {
            return repository
        }

        // Accept owner/repo shorthand: exactly one "/" with non-empty segments, no special characters
        let parts = repository.split(separator: "/", omittingEmptySubsequences: false)
        if parts.count == 2,
           parts.allSatisfy({ !$0.isEmpty }),
           !repository.contains(":"),
           !repository.contains("@") {
            return repository
        }

        throw SkillRepositoryResolverError.invalidRepositoryFormat(repository)
    }
}
