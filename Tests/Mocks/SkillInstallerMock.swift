//  SkillInstallerMock.swift

import Foundation
@testable import LucaCore

class SkillInstallerMock: SkillInstalling, @unchecked Sendable {

    var installedSkills: [Skill] = []
    var errorToThrow: Error?

    func install(skill: Skill) async throws {
        if let error = errorToThrow {
            throw error
        }
        installedSkills.append(skill)
    }
}
