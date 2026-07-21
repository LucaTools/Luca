//  Spec.swift

import Foundation

public typealias Agent = String

/// A specification defining the tools required for a project.
///
/// A `Spec` represents the parsed contents of a Lucafile. It contains
/// an array of ``Tool`` definitions that Luca will install and manage.
///
/// ## Lucafile Example
///
/// ```yaml
/// ---
/// repos:
///   vercel:
///     url: vercel-labs/agent-skills
///     version: v1.2.0
///   vanderlee: git@github.com:AvdLee/Swift-Testing-Agent-Skill.git
///
/// tools:
///   - name: SwiftLint
///     version: 0.61.0
///     url: https://github.com/realm/SwiftLint/releases/...
///   - name: Tuist
///     version: 4.80.0
///     url: https://github.com/tuist/tuist/releases/...
///
/// skills:
///   - name: frontend-design
///     repository: vercel       # inherits v1.2.0 from repo entry
///   - name: skill-creator
///     repository: vercel       # inherits v1.2.0 from repo entry
///   - name: swift-testing-expert
///     repository: vanderlee
///     version: abc1234         # explicit version overrides repo default
///   - name: swift-concurrency
///     repository: https://github.com/AvdLee/Swift-Concurrency-Agent-Skill.git
///     version: v2.0.0          # required when repo has no default version
/// ```
///
/// ## Topics
///
/// ### Properties
/// - ``tools``
/// - ``skills``
/// - ``agents``
///
/// ### Related Types
/// - ``Tool``
/// - ``Skill``
/// - ``SpecLoader``
public struct Spec: Codable {
    /// The list of tools defined in the specification.
    public let tools: [Tool]?
    /// The list of agentic skills defined in the specification.
    public let skills: [Skill]?
    /// The list of agent identifiers to target when installing skills (e.g. `claude-code`, `github-copilot`).
    /// When `nil`, skills are installed for all supported agents.
    public let agents: [Agent]?

    public init(tools: [Tool]?, skills: [Skill]?, agents: [Agent]?) {
        self.tools = tools
        self.skills = skills
        self.agents = agents
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let repos = try container.decodeIfPresent([String: RepoEntry].self, forKey: .repos)
        tools = try container.decodeIfPresent([Tool].self, forKey: .tools)
        let drafts = try container.decodeIfPresent([SkillDraft].self, forKey: .skills)
        if let drafts {
            skills = try drafts.map { draft in
                // Resolve repo alias to entry (if present), otherwise treat the value as a URL.
                let entry = repos?[draft.repository]
                let resolvedURL = entry?.url ?? draft.repository
                // Skill-level version takes precedence over repo-level version.
                let resolvedVersion = draft.version ?? entry?.version
                guard let version = resolvedVersion else {
                    throw Skill.SkillDecodingError.missingVersion(repository: resolvedURL)
                }
                return Skill(name: draft.name, repository: resolvedURL, version: version)
            }
        } else {
            skills = nil
        }
        agents = try container.decodeIfPresent([Agent].self, forKey: .agents)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeIfPresent(tools, forKey: .tools)
        try container.encodeIfPresent(skills, forKey: .skills)
        try container.encodeIfPresent(agents, forKey: .agents)
    }

    private enum CodingKeys: String, CodingKey {
        case repos, tools, skills, agents
    }
}

/// Raw skill entry decoded directly from YAML before repo alias and version resolution.
private struct SkillDraft: Decodable {
    let name: String?
    let repository: String
    let version: String?
}
