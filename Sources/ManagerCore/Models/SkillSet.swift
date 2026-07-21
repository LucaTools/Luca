//  SkillSet.swift

import Foundation

struct SkillSet: Codable {
    /// The repository reference — either `owner/repo` (GitHub shorthand) or a full HTTPS/GIT URL.
    let repository: String
    /// The skill names to install. An empty array means install all skills in the repository.
    let skills: [String]
    /// A git ref pinning the repository to a specific tag or commit SHA.
    let version: String

    init(repository: String, skills: [String], version: String) {
        self.repository = repository
        self.skills = skills
        self.version = version
    }
}
