//  SkillRepositoryResolver.swift

import Foundation

/// Passes a skill repository reference through to `npx skills add`.
///
/// The resolver is a thin pass-through: `npx skills add` accepts any string
/// (shorthand `owner/repo`, full HTTPS URL, SSH URL) and performs its own
/// validation, so no client-side gating is applied.
struct SkillRepositoryResolver {

    /// Returns the repository reference unchanged.
    ///
    /// - Parameter repository: Any repository reference accepted by `npx skills add`.
    /// - Returns: The repository reference, ready to pass to `npx skills add`.
    func resolve(_ repository: String) -> String {
        repository
    }
}
