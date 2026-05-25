//  SkillSymLinkerMock.swift

@testable import LucaCore
@testable import ManagerCore

final class SkillSymLinkerMock: SkillSymLinking, @unchecked Sendable {
    var setSymLinkCalled = false
    var lastSkillName: String?
    var lastAgents: [AgentInfo]?
    var lastIsGlobal: Bool?
    var shouldThrow: Bool = false

    func setSymLink(skillName: String, agents: [AgentInfo], isGlobal: Bool) throws {
        setSymLinkCalled = true
        lastSkillName = skillName
        lastAgents = agents
        lastIsGlobal = isGlobal
        if shouldThrow {
            throw SkillSymLinker.SkillSymLinkerError.symLinkCreationFailed(from: "", to: "")
        }
    }
}
