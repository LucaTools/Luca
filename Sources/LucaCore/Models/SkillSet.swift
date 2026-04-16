//  SkillSet.swift

import Foundation

struct SkillSet: Codable {
    /// The repository reference — either `owner/repo` (GitHub shorthand) or a full HTTPS/GIT URL
    let repository: String
    /// The skill names.
    let skills: [String]
    /// An optional git ref to pin the repository to. Accepts a tag (e.g. `v1.2.0`) or a commit SHA1 (e.g. `abc1234`).
    /// When `nil`, the default branch HEAD is used.
    let version: String?

    init(repository: String, skills: [String], version: String? = nil) {
        self.repository = repository
        self.skills = skills
        self.version = version
    }
}
