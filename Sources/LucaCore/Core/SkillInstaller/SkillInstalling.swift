//  SkillInstalling.swift

import Foundation

/// Installs an agentic skill set from a remote repository.
protocol SkillInstalling {
    /// Installs the given skill.
    ///
    /// - Parameters:
    ///   - skill: The ``Skill`` to install.
    ///   - agents: Agent identifiers to pass via `--agent` flags. `nil` installs for all supported agents.
    func install(skill: Skill, agents: [String]?) async throws
}
