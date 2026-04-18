//  SkillsInfoFactoryTests.swift

import Foundation
import Testing
@testable import LucaCore

struct SkillsInfoFactoryTests {

    // MARK: - Named skills

    @Test
    func test_skillsInfoForInstallationType_namedSkillSingleRepo_returnsOneSkillSet() async throws {
        let spec = Spec(tools: nil, skills: [
            Skill(name: "frontend-design", repository: "vercel-labs/agent-skills")
        ], agents: nil)
        let sut = SkillsInfoFactory(specLoader: SpecLoaderMock(spec: spec))

        let info = try await sut.skillsInfoForInstallationType(.spec(specPath: URL(fileURLWithPath: "/Lucafile")))

        #expect(info.skillSets.count == 1)
        let skillSet = try #require(info.skillSets.first)
        #expect(skillSet.repository == "vercel-labs/agent-skills")
        #expect(skillSet.skills == ["frontend-design"])
        #expect(info.agents == nil)
    }

    @Test
    func test_skillsInfoForInstallationType_multipleNamedSkillsSameRepo_mergesIntoOneSkillSet() async throws {
        let spec = Spec(tools: nil, skills: [
            Skill(name: "frontend-design", repository: "vercel-labs/agent-skills"),
            Skill(name: "skill-creator", repository: "vercel-labs/agent-skills")
        ], agents: nil)
        let sut = SkillsInfoFactory(specLoader: SpecLoaderMock(spec: spec))

        let info = try await sut.skillsInfoForInstallationType(.spec(specPath: URL(fileURLWithPath: "/Lucafile")))

        #expect(info.skillSets.count == 1)
        let skillSet = try #require(info.skillSets.first)
        #expect(skillSet.repository == "vercel-labs/agent-skills")
        #expect(Set(skillSet.skills) == Set(["frontend-design", "skill-creator"]))
    }

    @Test
    func test_skillsInfoForInstallationType_namedSkillsDifferentRepos_returnsMultipleSkillSets() async throws {
        let spec = Spec(tools: nil, skills: [
            Skill(name: "frontend-design", repository: "vercel-labs/agent-skills"),
            Skill(name: "swift-testing-expert", repository: "https://github.com/AvdLee/Swift-Testing-Agent-Skill")
        ], agents: nil)
        let sut = SkillsInfoFactory(specLoader: SpecLoaderMock(spec: spec))

        let info = try await sut.skillsInfoForInstallationType(.spec(specPath: URL(fileURLWithPath: "/Lucafile")))

        #expect(info.skillSets.count == 2)
        let repositories = Set(info.skillSets.map(\.repository))
        #expect(repositories.contains("vercel-labs/agent-skills"))
        #expect(repositories.contains("https://github.com/AvdLee/Swift-Testing-Agent-Skill"))
    }

    // MARK: - "Install all" (nil name) overrides named entries

    @Test
    func test_skillsInfoForInstallationType_allSkillsEntryAlone_returnsEmptySkillsArray() async throws {
        let spec = Spec(tools: nil, skills: [
            Skill(name: nil, repository: "vercel-labs/agent-skills")
        ], agents: nil)
        let sut = SkillsInfoFactory(specLoader: SpecLoaderMock(spec: spec))

        let info = try await sut.skillsInfoForInstallationType(.spec(specPath: URL(fileURLWithPath: "/Lucafile")))

        #expect(info.skillSets.count == 1)
        let skillSet = try #require(info.skillSets.first)
        #expect(skillSet.repository == "vercel-labs/agent-skills")
        #expect(skillSet.skills.isEmpty)
    }

    @Test
    func test_skillsInfoForInstallationType_allSkillsOverridesNamedEntryForSameRepo() async throws {
        // nil-name entry wins; the named entry is discarded
        let spec = Spec(tools: nil, skills: [
            Skill(name: "frontend-design", repository: "vercel-labs/agent-skills"),
            Skill(name: nil, repository: "vercel-labs/agent-skills")
        ], agents: nil)
        let sut = SkillsInfoFactory(specLoader: SpecLoaderMock(spec: spec))

        let info = try await sut.skillsInfoForInstallationType(.spec(specPath: URL(fileURLWithPath: "/Lucafile")))

        #expect(info.skillSets.count == 1)
        let skillSet = try #require(info.skillSets.first)
        #expect(skillSet.repository == "vercel-labs/agent-skills")
        #expect(skillSet.skills.isEmpty, "nil-name entry must override named entry — empty skills means install all")
    }

    @Test
    func test_skillsInfoForInstallationType_mixedRepos_allSkillsOnlyAffectsItsRepo() async throws {
        let spec = Spec(tools: nil, skills: [
            Skill(name: "frontend-design", repository: "vercel-labs/agent-skills"),
            Skill(name: nil, repository: "other-org/other-skills")
        ], agents: nil)
        let sut = SkillsInfoFactory(specLoader: SpecLoaderMock(spec: spec))

        let info = try await sut.skillsInfoForInstallationType(.spec(specPath: URL(fileURLWithPath: "/Lucafile")))

        #expect(info.skillSets.count == 2)
        let vercelSet = try #require(info.skillSets.first(where: { $0.repository == "vercel-labs/agent-skills" }))
        #expect(vercelSet.skills == ["frontend-design"])
        let otherSet = try #require(info.skillSets.first(where: { $0.repository == "other-org/other-skills" }))
        #expect(otherSet.skills.isEmpty)
    }

    // MARK: - Agents propagation

    @Test
    func test_skillsInfoForInstallationType_agentsPropagated() async throws {
        let spec = Spec(tools: nil, skills: [
            Skill(name: "frontend-design", repository: "vercel-labs/agent-skills")
        ], agents: ["claude-code", "github-copilot"])
        let sut = SkillsInfoFactory(specLoader: SpecLoaderMock(spec: spec))

        let info = try await sut.skillsInfoForInstallationType(.spec(specPath: URL(fileURLWithPath: "/Lucafile")))

        #expect(info.agents == ["claude-code", "github-copilot"])
    }

    // MARK: - Individual installation type

    @Test
    func test_skillsInfoForInstallationType_individual_allSkills() async throws {
        let sut = SkillsInfoFactory(specLoader: SpecLoaderMock(spec: Spec(tools: nil, skills: nil, agents: nil)))

        let info = try await sut.skillsInfoForInstallationType(
            .individual(repository: "owner/repo", skillNames: [], agents: nil, ref: nil)
        )

        #expect(info.skillSets.count == 1)
        let skillSet = try #require(info.skillSets.first)
        #expect(skillSet.repository == "owner/repo")
        #expect(skillSet.skills.isEmpty)
        #expect(info.agents == nil)
    }

    @Test
    func test_skillsInfoForInstallationType_individual_filteredSkills() async throws {
        let sut = SkillsInfoFactory(specLoader: SpecLoaderMock(spec: Spec(tools: nil, skills: nil, agents: nil)))

        let info = try await sut.skillsInfoForInstallationType(
            .individual(repository: "owner/repo", skillNames: ["skill-a"], agents: ["claude-code"], ref: nil)
        )

        #expect(info.skillSets.count == 1)
        let skillSet = try #require(info.skillSets.first)
        #expect(skillSet.repository == "owner/repo")
        #expect(skillSet.skills == ["skill-a"])
        #expect(info.agents == ["claude-code"])
    }

    // MARK: - Version propagation

    @Test
    func test_skillsInfoForInstallationType_skillWithVersion_propagatesVersionToSkillSet() async throws {
        let spec = Spec(tools: nil, skills: [
            Skill(name: "frontend-design", repository: "vercel-labs/agent-skills", version: "v1.2.0")
        ], agents: nil)
        let sut = SkillsInfoFactory(specLoader: SpecLoaderMock(spec: spec))

        let info = try await sut.skillsInfoForInstallationType(.spec(specPath: URL(fileURLWithPath: "/Lucafile")))

        let skillSet = try #require(info.skillSets.first)
        #expect(skillSet.version == "v1.2.0")
    }

    @Test
    func test_skillsInfoForInstallationType_skillWithNoVersion_versionIsNil() async throws {
        let spec = Spec(tools: nil, skills: [
            Skill(name: "frontend-design", repository: "vercel-labs/agent-skills")
        ], agents: nil)
        let sut = SkillsInfoFactory(specLoader: SpecLoaderMock(spec: spec))

        let info = try await sut.skillsInfoForInstallationType(.spec(specPath: URL(fileURLWithPath: "/Lucafile")))

        let skillSet = try #require(info.skillSets.first)
        #expect(skillSet.version == nil)
    }

    @Test
    func test_skillsInfoForInstallationType_multipleSkillsSameRepoFirstVersionWins() async throws {
        let spec = Spec(tools: nil, skills: [
            Skill(name: "skill-a", repository: "vercel-labs/agent-skills", version: "v1.0.0"),
            Skill(name: "skill-b", repository: "vercel-labs/agent-skills", version: "v2.0.0")
        ], agents: nil)
        let sut = SkillsInfoFactory(specLoader: SpecLoaderMock(spec: spec))

        let info = try await sut.skillsInfoForInstallationType(.spec(specPath: URL(fileURLWithPath: "/Lucafile")))

        let skillSet = try #require(info.skillSets.first)
        #expect(skillSet.version == "v1.0.0")
    }

    @Test
    func test_skillsInfoForInstallationType_individual_withRef_propagatedToSkillSet() async throws {
        let sut = SkillsInfoFactory(specLoader: SpecLoaderMock(spec: Spec(tools: nil, skills: nil, agents: nil)))

        let info = try await sut.skillsInfoForInstallationType(
            .individual(repository: "owner/repo", skillNames: ["skill-a"], agents: nil, ref: "abc1234")
        )

        let skillSet = try #require(info.skillSets.first)
        #expect(skillSet.version == "abc1234")
    }

    // MARK: - Empty skills

    @Test
    func test_skillsInfoForInstallationType_emptySkillsInSpec_returnsEmptySkillSets() async throws {
        let spec = Spec(tools: nil, skills: [], agents: nil)
        let sut = SkillsInfoFactory(specLoader: SpecLoaderMock(spec: spec))

        let info = try await sut.skillsInfoForInstallationType(.spec(specPath: URL(fileURLWithPath: "/Lucafile")))

        #expect(info.skillSets.isEmpty)
    }

    @Test
    func test_skillsInfoForInstallationType_nilSkillsInSpec_returnsEmptySkillSets() async throws {
        let spec = Spec(tools: nil, skills: nil, agents: nil)
        let sut = SkillsInfoFactory(specLoader: SpecLoaderMock(spec: spec))

        let info = try await sut.skillsInfoForInstallationType(.spec(specPath: URL(fileURLWithPath: "/Lucafile")))

        #expect(info.skillSets.isEmpty)
    }
}

// MARK: - Private mock

private struct SpecLoaderMock: SpecLoading {
    let spec: Spec

    func loadSpec(at path: URL) throws -> Spec {
        spec
    }
}
