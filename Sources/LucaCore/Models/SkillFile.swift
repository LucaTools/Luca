//  SkillFile.swift

import Foundation

/// A single file that belongs to an agentic skill.
///
/// `SkillFile` pairs a file's content with its path relative to the skill's root directory.
/// For example, a skill named `find-skills` may contain:
/// - `relativePath: "SKILL.md"`, the skill definition
/// - `relativePath: "resources/template.md"`, an auxiliary resource
public struct SkillFile: Equatable, Sendable {
    /// The path of this file relative to the skill's root directory.
    ///
    /// For example `"SKILL.md"` or `"resources/template.md"`.
    public let relativePath: String

    /// The raw content of the file.
    public let content: Data
}
