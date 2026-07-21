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
public struct Skill: Codable {

    /// Errors thrown when decoding a ``Skill`` from a spec file.
    public enum SkillDecodingError: Error, LocalizedError, Equatable {
        /// The `version` field is absent for the given repository.
        case missingVersion(repository: String)

        public var errorDescription: String? {
            switch self {
            case .missingVersion(let repository):
                return "Skill from '\(repository)' is missing a required 'version' field. Specify a git tag or commit SHA (e.g. version: v1.2.0)."
            }
        }
    }

    /// The name of the specific skill to install. `nil` installs all available skills from the repository.
    public let name: String?
    /// The repository reference — either `owner/repo` (GitHub shorthand) or a full HTTPS/GIT URL.
    public let repository: String
    /// A git ref pinning the skill. Accepts a tag (e.g. `v1.2.0`) or a commit SHA (e.g. `abc1234`).
    public let version: String

    public init(name: String?, repository: String, version: String) {
        self.name = name
        self.repository = repository
        self.version = version
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        name = try container.decodeIfPresent(String.self, forKey: .name)
        repository = try container.decode(String.self, forKey: .repository)
        guard let version = try container.decodeIfPresent(String.self, forKey: .version) else {
            throw SkillDecodingError.missingVersion(repository: repository)
        }
        self.version = version
    }

    private enum CodingKeys: String, CodingKey {
        case name, repository, version
    }
}
