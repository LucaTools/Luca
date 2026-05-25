//  AgentRegistryTests.swift

import Foundation
import Testing
@testable import LucaFoundation
@testable import ManagerCore

struct AgentRegistryTests {

    init() async throws {}

    // MARK: - agents(for:)

    @Test
    func test_agents_forIds_returnsMatchingAgents() {
        let result = AgentRegistry.agents(for: ["claude-code", "cursor"])
        #expect(result.count == 2)
        #expect(result[0].id == "claude-code")
        #expect(result[1].id == "cursor")
    }

    @Test
    func test_agents_forIds_ignoresUnknownIds() {
        let result = AgentRegistry.agents(for: ["claude-code", "unknown-agent-xyz"])
        #expect(result.count == 1)
        #expect(result[0].id == "claude-code")
    }

    @Test
    func test_agents_forIds_emptyList_returnsEmpty() {
        let result = AgentRegistry.agents(for: [])
        #expect(result.isEmpty)
    }

    // MARK: - allAgentIds()

    @Test
    func test_allAgentIds_isNonEmpty() {
        #expect(!AgentRegistry.allAgentIds().isEmpty)
    }

    @Test
    func test_allAgentIds_containsKnownAgents() {
        let ids = AgentRegistry.allAgentIds()
        #expect(ids.contains("claude-code"))
        #expect(ids.contains("cursor"))
    }

    // MARK: - all

    @Test
    func test_all_hasExpectedCount() {
        #expect(AgentRegistry.all.count == 45)
    }

    @Test
    func test_allAgentIds_isSorted() {
        let ids = AgentRegistry.allAgentIds()
        #expect(ids == ids.sorted())
    }

    @Test
    func test_agents_forIds_hasCorrectPaths() {
        let claudeCode = AgentRegistry.agents(for: ["claude-code"]).first
        #expect(claudeCode?.projectSkillsPath == ".claude/skills")
        let cursor = AgentRegistry.agents(for: ["cursor"]).first
        #expect(cursor?.projectSkillsPath == ".agents/skills")
    }

    // MARK: - AgentInfo.resolvedGlobalSkillsPath

    @Test
    func test_resolvedGlobalSkillsPath_withTildeSlashPrefix_expandsToHomeDirectory() {
        let homeDirectory = URL(fileURLWithPath: "/Users/testuser")
        let agentInfo = AgentInfo(id: "test", projectSkillsPath: ".test/skills", globalSkillsPath: "~/.test/skills")

        let resolved = agentInfo.resolvedGlobalSkillsPath(homeDirectory: homeDirectory)

        #expect(resolved == URL(fileURLWithPath: "/Users/testuser/.test/skills"))
    }

    @Test
    func test_resolvedGlobalSkillsPath_withBareGlobalPath_noTilde_returnsAsIs() {
        let homeDirectory = URL(fileURLWithPath: "/Users/testuser")
        let agentInfo = AgentInfo(id: "test", projectSkillsPath: ".test/skills", globalSkillsPath: "/absolute/path/skills")

        let resolved = agentInfo.resolvedGlobalSkillsPath(homeDirectory: homeDirectory)

        #expect(resolved == URL(fileURLWithPath: "/absolute/path/skills"))
    }

    @Test
    func test_resolvedGlobalSkillsPath_withBareHome_returnsHomeDirectory() {
        let homeDirectory = URL(fileURLWithPath: "/Users/testuser")
        let agentInfo = AgentInfo(id: "test", projectSkillsPath: ".test/skills", globalSkillsPath: "~")

        let resolved = agentInfo.resolvedGlobalSkillsPath(homeDirectory: homeDirectory)

        #expect(resolved == homeDirectory)
    }
}
