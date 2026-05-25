//  SkillInstalling.swift

import Foundation

/// Installs a set of agentic skills from a remote repository.
protocol SkillInstalling {
    /// Installs the given skill.
    ///
    /// - Parameters:
    ///   - skillSet: The ``SkillSet`` to install.
    ///   - agents: Agent identifiers. `nil` installs for all supported agents.
    func install(skillSet: SkillSet, agents: [String]?) async throws
}
