//  Skill.swift

import Foundation

/// A skill entry defined in the Lucafile.
///
/// A `Skill` represents an agentic skill set hosted in a Git repository.
/// Luca installs skills by delegating to `npx skills add`.
///
/// ## Lucafile Example
///
/// ```yaml
/// skills:
///   - name: vercel-labs-agent-skills
///     repository: vercel-labs/agent-skills
///     skills:
///       - frontend-design
///       - skill-creator
///   - name: ai-platform-skills
///     repository: https://github.je-labs.com/ai-platform/skills.git
/// ```
///
/// ## Topics
///
/// ### Properties
/// - ``name``
/// - ``repository``
/// - ``skills``
struct Skill: Codable {
    /// A human-readable identifier for the skill set.
    let name: String
    /// The repository reference — either `owner/repo` (GitHub shorthand) or a full HTTPS URL.
    let repository: String
    /// The individual skill names to install. When `nil`, all skills in the repository are installed.
    let skills: [String]?
}
