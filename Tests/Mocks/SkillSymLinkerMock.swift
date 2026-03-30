//  SkillSymLinkerMock.swift

@testable import LucaCore

final class SkillSymLinkerMock: SkillSymLinking, @unchecked Sendable {
    var setSymLinkCalled = false
    var lastSkillName: String?
    var lastAgents: [AgentInfo]?
    var shouldThrow: Bool = false

    func setSymLink(skillName: String, agents: [AgentInfo]) throws {
        setSymLinkCalled = true
        lastSkillName = skillName
        lastAgents = agents
        if shouldThrow {
            throw SkillSymLinker.SkillSymLinkerError.symLinkCreationFailed(from: "", to: "")
        }
    }
}
