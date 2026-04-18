//  Spec.swift

import Foundation

typealias Agent = String

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
///   vercel: vercel-labs/agent-skills
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
///     repository: vercel
///     version: v1.2.0
///   - name: skill-creator
///     repository: vercel
///   - name: swift-testing-expert
///     repository: vanderlee
///     version: abc1234
///   - name: swift-concurrency
///     repository: https://github.com/AvdLee/Swift-Concurrency-Agent-Skill.git
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
struct Spec: Codable {
    /// The list of tools defined in the specification.
    let tools: [Tool]?
    /// The list of agentic skills defined in the specification.
    let skills: [Skill]?
    /// The list of agent identifiers to target when installing skills (e.g. `claude-code`, `github-copilot`).
    /// When `nil`, skills are installed for all supported agents.
    let agents: [Agent]?

    init(tools: [Tool]?, skills: [Skill]?, agents: [Agent]?) {
        self.tools = tools
        self.skills = skills
        self.agents = agents
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let repos = try container.decodeIfPresent([String: String].self, forKey: .repos)
        tools = try container.decodeIfPresent([Tool].self, forKey: .tools)
        let rawSkills = try container.decodeIfPresent([Skill].self, forKey: .skills)
        if let rawSkills, let repos {
            skills = rawSkills.map { skill in
                Skill(name: skill.name, repository: repos[skill.repository] ?? skill.repository, version: skill.version)
            }
        } else {
            skills = rawSkills
        }
        agents = try container.decodeIfPresent([Agent].self, forKey: .agents)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeIfPresent(tools, forKey: .tools)
        try container.encodeIfPresent(skills, forKey: .skills)
        try container.encodeIfPresent(agents, forKey: .agents)
    }

    private enum CodingKeys: String, CodingKey {
        case repos, tools, skills, agents
    }
}
