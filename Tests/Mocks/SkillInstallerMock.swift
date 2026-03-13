//  SkillInstallerMock.swift

import Foundation
@testable import LucaCore

class SkillInstallerMock: SkillInstalling, @unchecked Sendable {

    struct Call {
        let skill: Skill
        let agents: [String]?
    }

    var calls: [Call] = []
    var errorToThrow: Error?

    var installedSkills: [Skill] { calls.map(\.skill) }

    func install(skill: Skill, agents: [String]?) async throws {
        if let error = errorToThrow {
            throw error
        }
        calls.append(Call(skill: skill, agents: agents))
    }
}
