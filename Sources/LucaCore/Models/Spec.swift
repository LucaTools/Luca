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
///     repository: vercel-labs/agent-skills
///   - name: skill-creator
///     repository: vercel-labs/agent-skills
///   - name: swift-testing-expert
///     repository: https://github.com/AvdLee/Swift-Testing-Agent-Skill
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
}
