//  SkillInstallerTests.swift

import Foundation
import Testing
@testable import LucaCore

struct SkillInstallerTests {

    // MARK: - Argument construction

    @Test
    func test_install_noSkillsNoAgents_invokesNpxWithoutFlags() async throws {
        let runner = SubprocessRunnerMock()
        let installer = SkillInstaller(subprocessRunner: runner)
        let skill = Skill(name: "ai-skills", repository: "some-org/ai-skills", skills: nil)

        try await installer.install(skill: skill, agents: nil)

        // First call: which npx; Second call: npx skills add
        #expect(runner.recordedArguments.count == 2)
        let npxCall = runner.recordedArguments[1]
        #expect(npxCall == ["npx", "skills", "add", "some-org/ai-skills", "--yes"])
    }

    @Test
    func test_install_withSkillsList_appendsSkillFlags() async throws {
        let runner = SubprocessRunnerMock()
        let installer = SkillInstaller(subprocessRunner: runner)
        let skill = Skill(name: "vercel-skills", repository: "vercel-labs/agent-skills", skills: ["frontend-design", "skill-creator"])

        try await installer.install(skill: skill, agents: nil)

        let npxCall = runner.recordedArguments[1]
        #expect(npxCall == ["npx", "skills", "add", "vercel-labs/agent-skills", "--yes", "--skill", "frontend-design", "--skill", "skill-creator"])
    }

    @Test
    func test_install_withAgents_appendsAgentFlags() async throws {
        let runner = SubprocessRunnerMock()
        let installer = SkillInstaller(subprocessRunner: runner)
        let skill = Skill(name: "ai-skills", repository: "some-org/ai-skills", skills: nil)

        try await installer.install(skill: skill, agents: ["claude-code", "github-copilot"])

        let npxCall = runner.recordedArguments[1]
        #expect(npxCall == ["npx", "skills", "add", "some-org/ai-skills", "--yes", "--agent", "claude-code", "--agent", "github-copilot"])
    }

    @Test
    func test_install_withSkillsAndAgents_appendsBothFlags() async throws {
        let runner = SubprocessRunnerMock()
        let installer = SkillInstaller(subprocessRunner: runner)
        let skill = Skill(name: "vercel-skills", repository: "vercel-labs/agent-skills", skills: ["deploy-to-vercel"])

        try await installer.install(skill: skill, agents: ["claude-code", "opencode"])

        let npxCall = runner.recordedArguments[1]
        #expect(npxCall == ["npx", "skills", "add", "vercel-labs/agent-skills", "--yes", "--skill", "deploy-to-vercel", "--agent", "claude-code", "--agent", "opencode"])
    }

    @Test
    func test_install_sshUrl_passesRepositoryAsIs() async throws {
        let runner = SubprocessRunnerMock()
        let installer = SkillInstaller(subprocessRunner: runner)
        let skill = Skill(name: "platform-skills", repository: "git@github.je-labs.com:ai-platform/skills.git", skills: nil)

        try await installer.install(skill: skill, agents: nil)

        let npxCall = runner.recordedArguments[1]
        #expect(npxCall[3] == "git@github.je-labs.com:ai-platform/skills.git")
    }

    // MARK: - npx unavailable

    @Test
    func test_install_npxNotAvailable_throwsNpxNotAvailable() async throws {
        let runner = SubprocessRunnerMock()
        runner.exitCodes = [1] // which npx fails
        let installer = SkillInstaller(subprocessRunner: runner)
        let skill = Skill(name: "ai-skills", repository: "some-org/ai-skills", skills: nil)

        await #expect(throws: SkillInstaller.SkillInstallerError.npxNotAvailable) {
            try await installer.install(skill: skill, agents: nil)
        }
    }

    // MARK: - Non-zero exit code

    @Test
    func test_install_npxExitsNonZero_throwsInstallationFailed() async throws {
        let runner = SubprocessRunnerMock()
        runner.exitCodes = [0, 1] // which npx succeeds, npx skills add fails
        let installer = SkillInstaller(subprocessRunner: runner)
        let skill = Skill(name: "ai-skills", repository: "some-org/ai-skills", skills: nil)

        await #expect(throws: SkillInstaller.SkillInstallerError.installationFailed("ai-skills", 1)) {
            try await installer.install(skill: skill, agents: nil)
        }
    }
}
