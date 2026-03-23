//  SkillInstallerMock.swift

import Foundation
@testable import LucaCore

class SkillInstallerMock: SkillInstalling, @unchecked Sendable {

    struct Call {
        let skillSet: SkillSet
        let agents: [String]?
    }

    var calls: [Call] = []
    var errorToThrow: Error?

    var installedSkillSets: [SkillSet] { calls.map(\.skillSet) }

    func install(skillSet: SkillSet, agents: [String]?) async throws {
        if let error = errorToThrow {
            throw error
        }
        calls.append(Call(skillSet: skillSet, agents: agents))
    }
}
