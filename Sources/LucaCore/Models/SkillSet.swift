//  SkillSet.swift

import Foundation

struct SkillSet: Codable {
    /// The repository reference — either `owner/repo` (GitHub shorthand) or a full HTTPS/GIT URL
    let repository: String
    /// The skill names.
    let skills: [String]
}
