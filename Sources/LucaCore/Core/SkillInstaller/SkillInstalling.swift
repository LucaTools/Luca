//  SkillInstalling.swift

import Foundation

/// Installs an agentic skill set from a remote repository.
protocol SkillInstalling {
    /// Installs the given skill.
    ///
    /// - Parameter skill: The ``Skill`` to install.
    func install(skill: Skill) async throws
}
