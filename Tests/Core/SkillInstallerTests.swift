//  SkillInstallerTests.swift

import Foundation
import Testing
@testable import LucaCore

struct SkillInstallerTests {

    // MARK: - Argument construction

    @Test
    func test_install_noSkillsList_invokesNpxWithoutSkillFlags() async throws {
        let runner = SubprocessRunnerMock()
        let installer = SkillInstaller(subprocessRunner: runner)
        let skill = Skill(name: "ai-skills", repository: "some-org/ai-skills", skills: nil)

        try await installer.install(skill: skill)

        // First call: which npx; Second call: npx skills add
        #expect(runner.recordedArguments.count == 2)
        let npxCall = runner.recordedArguments[1]
        #expect(npxCall == ["npx", "skills", "add", "some-org/ai-skills"])
    }

    @Test
    func test_install_withSkillsList_appendsSkillFlags() async throws {
        let runner = SubprocessRunnerMock()
        let installer = SkillInstaller(subprocessRunner: runner)
        let skill = Skill(name: "vercel-skills", repository: "vercel-labs/agent-skills", skills: ["frontend-design", "skill-creator"])

        try await installer.install(skill: skill)

        let npxCall = runner.recordedArguments[1]
        #expect(npxCall == ["npx", "skills", "add", "vercel-labs/agent-skills", "--skill", "frontend-design", "--skill", "skill-creator"])
    }

    @Test
    func test_install_fullUrl_passesRepositoryAsIs() async throws {
        let runner = SubprocessRunnerMock()
        let installer = SkillInstaller(subprocessRunner: runner)
        let skill = Skill(name: "platform-skills", repository: "https://github.je-labs.com/ai-platform/skills.git", skills: nil)

        try await installer.install(skill: skill)

        let npxCall = runner.recordedArguments[1]
        #expect(npxCall[3] == "https://github.je-labs.com/ai-platform/skills.git")
    }

    // MARK: - npx unavailable

    @Test
    func test_install_npxNotAvailable_throwsNpxNotAvailable() async throws {
        let runner = SubprocessRunnerMock()
        runner.exitCodes = [1] // which npx fails
        let installer = SkillInstaller(subprocessRunner: runner)
        let skill = Skill(name: "ai-skills", repository: "some-org/ai-skills", skills: nil)

        await #expect(throws: SkillInstaller.SkillInstallerError.npxNotAvailable) {
            try await installer.install(skill: skill)
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
            try await installer.install(skill: skill)
        }
    }

    // MARK: - Invalid repository

    @Test
    func test_install_invalidRepository_throwsBeforeRunning() async throws {
        let runner = SubprocessRunnerMock()
        let installer = SkillInstaller(subprocessRunner: runner)
        let skill = Skill(name: "bad-skill", repository: "not-valid-format", skills: nil)

        await #expect(throws: SkillRepositoryResolver.SkillRepositoryResolverError.invalidRepositoryFormat("not-valid-format")) {
            try await installer.install(skill: skill)
        }
        #expect(runner.recordedArguments.isEmpty)
    }
}
