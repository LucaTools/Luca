//  Skill.swift

import Foundation

/// A skill definition.
///
/// A `Skill` represents an agentic skill hosted in a Git repository.
///
/// ### Properties
/// - ``name``
/// - ``repository``
/// - ``version``
struct Skill: Codable {
    /// The name of the specific skill to install. Leaving this `nil` indicates that all available skills should be installed.
    let name: String?
    /// The repository reference — either `owner/repo` (GitHub shorthand) or a full HTTPS/GIT URL
    let repository: String
    /// An optional git ref to pin the skill to. Accepts a tag (e.g. `v1.2.0`) or a commit SHA1 (e.g. `abc1234`).
    /// When `nil`, the default branch HEAD is used.
    let version: String?

    init(name: String?, repository: String, version: String? = nil) {
        self.name = name
        self.repository = repository
        self.version = version
    }
}
