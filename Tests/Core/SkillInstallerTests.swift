//  SkillInstallerTests.swift

import Foundation
import Testing
@testable import LucaFoundation
@testable import ManagerCore

struct SkillInstallerTests {

    // MARK: - Argument construction

    @Test
    func test_install_noSkillsNoAgents_invokesNpxWithoutFlags() async throws {
        let runner = SubprocessRunnerMock()
        let installer = SkillInstaller(subprocessRunner: runner)
        let skillSet = SkillSet(repository: "some-org/ai-skills", skills: [], version: "v1.0.0")

        try await installer.install(skillSet: skillSet, agents: nil)

        // First call: which npx; Second call: npx skills add
        #expect(runner.recordedArguments.count == 2)
        let npxCall = runner.recordedArguments[1]
        #expect(npxCall == ["npx", "skills", "add", "some-org/ai-skills", "--yes"])
    }

    @Test
    func test_install_withSkillsList_appendsSkillFlags() async throws {
        let runner = SubprocessRunnerMock()
        let installer = SkillInstaller(subprocessRunner: runner)
        let skillSet = SkillSet(repository: "vercel-labs/agent-skills", skills: ["frontend-design", "skill-creator"], version: "v1.0.0")

        try await installer.install(skillSet: skillSet, agents: nil)

        let npxCall = runner.recordedArguments[1]
        #expect(npxCall == ["npx", "skills", "add", "vercel-labs/agent-skills", "--yes", "--skill", "frontend-design", "--skill", "skill-creator"])
    }

    @Test
    func test_install_withAgents_appendsAgentFlags() async throws {
        let runner = SubprocessRunnerMock()
        let installer = SkillInstaller(subprocessRunner: runner)
        let skillSet = SkillSet(repository: "some-org/ai-skills", skills: [], version: "v1.0.0")

        try await installer.install(skillSet: skillSet, agents: ["claude-code", "github-copilot"])

        let npxCall = runner.recordedArguments[1]
        #expect(npxCall == ["npx", "skills", "add", "some-org/ai-skills", "--yes", "--agent", "claude-code", "--agent", "github-copilot"])
    }

    @Test
    func test_install_withSkillsAndAgents_appendsBothFlags() async throws {
        let runner = SubprocessRunnerMock()
        let installer = SkillInstaller(subprocessRunner: runner)
        let skillSet = SkillSet(repository: "vercel-labs/agent-skills", skills: ["deploy-to-vercel"], version: "v1.0.0")

        try await installer.install(skillSet: skillSet, agents: ["claude-code", "opencode"])

        let npxCall = runner.recordedArguments[1]
        #expect(npxCall == ["npx", "skills", "add", "vercel-labs/agent-skills", "--yes", "--skill", "deploy-to-vercel", "--agent", "claude-code", "--agent", "opencode"])
    }

    @Test
    func test_install_httpsUrl_passesRepositoryAsIs() async throws {
        let runner = SubprocessRunnerMock()
        let installer = SkillInstaller(subprocessRunner: runner)
        let skillSet = SkillSet(repository: "https://github.com/AvdLee/Swift-Testing-Agent-Skill", skills: [], version: "v1.0.0")

        try await installer.install(skillSet: skillSet, agents: nil)

        let npxCall = runner.recordedArguments[1]
        #expect(npxCall[3] == "https://github.com/AvdLee/Swift-Testing-Agent-Skill")
    }

    // MARK: - npx unavailable

    @Test
    func test_install_npxNotAvailable_throwsNpxNotAvailable() async throws {
        let runner = SubprocessRunnerMock()
        runner.exitCodes = [1] // which npx fails
        let installer = SkillInstaller(subprocessRunner: runner)
        let skillSet = SkillSet(repository: "some-org/ai-skills", skills: [], version: "v1.0.0")

        await #expect(throws: SkillInstaller.SkillInstallerError.npxNotAvailable) {
            try await installer.install(skillSet: skillSet, agents: nil)
        }
    }

    // MARK: - Non-zero exit code

    @Test
    func test_install_npxExitsNonZero_throwsInstallationFailed() async throws {
        let runner = SubprocessRunnerMock()
        runner.exitCodes = [0, 1] // which npx succeeds, npx skills add fails
        let installer = SkillInstaller(subprocessRunner: runner)
        let skillSet = SkillSet(repository: "some-org/ai-skills", skills: [], version: "v1.0.0")

        await #expect(throws: SkillInstaller.SkillInstallerError.installationFailed("some-org/ai-skills", 1)) {
            try await installer.install(skillSet: skillSet, agents: nil)
        }
    }
}
