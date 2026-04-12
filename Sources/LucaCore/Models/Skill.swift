//  Skill.swift

import Foundation

/// A skill definition.
///
/// A `Skill` represents an agentic skill hosted in a Git repository.
///
/// ### Properties
/// - ``name``
/// - ``repository``
struct Skill: Codable {
    /// The name of the specific skill to install. Leaving this `nil` indicates that all available skills should be installed.
    let name: String?
    /// The repository reference — either `owner/repo` (GitHub shorthand) or a full HTTPS/GIT URL
    let repository: String
}
