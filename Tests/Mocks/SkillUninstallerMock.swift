//  SkillUninstallerMock.swift

import Foundation
@testable import LucaCore

/// Mock for ``SkillUninstaller`` used in CLI-layer tests.
final class SkillUninstallerMock: @unchecked Sendable {
    var uninstallCalled = false
    var lastSkillName: String?
    var shouldThrow: Bool = false
    var thrownError: Error = SkillUninstaller.SkillUninstallerError.skillNotFound(name: "")

    func uninstall(skillName: String, agents: [AgentInfo]) throws {
        if shouldThrow {
            throw thrownError
        }
        uninstallCalled = true
        lastSkillName = skillName
    }
}
