//  SkillLatestVersionResolverTests.swift

import Foundation
import Testing
@testable import ManagerCore

struct SkillLatestVersionResolverTests {

    @Test
    func test_resolveLatestVersion_parsesShaFromLsRemoteOutput() async throws {
        let runner = SubprocessOutputRunnerMock()
        runner.results = [(0, "947ad5941cddb8bd7d998129a642f43f0deb5c5f\tHEAD\n")]
        let sut = SkillLatestVersionResolver(outputRunner: runner)

        let sha = try await sut.resolveLatestVersion(repository: "owner/repo")

        #expect(sha == "947ad5941cddb8bd7d998129a642f43f0deb5c5f")
    }

    @Test
    func test_resolveLatestVersion_expandsShorthandRepositoryToGitHubURL() async throws {
        let runner = SubprocessOutputRunnerMock()
        runner.results = [(0, "947ad5941cddb8bd7d998129a642f43f0deb5c5f\tHEAD\n")]
        let sut = SkillLatestVersionResolver(outputRunner: runner)

        _ = try await sut.resolveLatestVersion(repository: "owner/repo")

        let args = try #require(runner.recordedArguments.first)
        #expect(args == ["ls-remote", "--quiet", "https://github.com/owner/repo", "HEAD"])
    }

    @Test
    func test_resolveLatestVersion_passesThroughExplicitURLsUnchanged() async throws {
        let runner = SubprocessOutputRunnerMock()
        runner.results = [(0, "947ad5941cddb8bd7d998129a642f43f0deb5c5f\tHEAD\n")]
        let sut = SkillLatestVersionResolver(outputRunner: runner)

        _ = try await sut.resolveLatestVersion(repository: "git@github.com:owner/repo.git")

        let args = try #require(runner.recordedArguments.first)
        #expect(args == ["ls-remote", "--quiet", "git@github.com:owner/repo.git", "HEAD"])
    }

    @Test
    func test_resolveLatestVersion_disablesGitTerminalPrompt() async throws {
        let runner = SubprocessOutputRunnerMock()
        runner.results = [(0, "947ad5941cddb8bd7d998129a642f43f0deb5c5f\tHEAD\n")]
        let sut = SkillLatestVersionResolver(outputRunner: runner)

        _ = try await sut.resolveLatestVersion(repository: "owner/repo")

        let env = try #require(runner.recordedEnvironments.first)
        #expect(env["GIT_TERMINAL_PROMPT"] == "0")
    }

    @Test
    func test_resolveLatestVersion_nonZeroExit_throwsLsRemoteFailed() async throws {
        let runner = SubprocessOutputRunnerMock()
        runner.results = [(128, "")]
        let sut = SkillLatestVersionResolver(outputRunner: runner)

        await #expect(throws: SkillLatestVersionResolver.SkillLatestVersionResolverError.lsRemoteFailed(repository: "owner/repo", exitCode: 128)) {
            try await sut.resolveLatestVersion(repository: "owner/repo")
        }
    }

    @Test
    func test_resolveLatestVersion_emptyOutput_throwsHeadRefNotFound() async throws {
        let runner = SubprocessOutputRunnerMock()
        runner.results = [(0, "")]
        let sut = SkillLatestVersionResolver(outputRunner: runner)

        await #expect(throws: SkillLatestVersionResolver.SkillLatestVersionResolverError.headRefNotFound(repository: "owner/repo")) {
            try await sut.resolveLatestVersion(repository: "owner/repo")
        }
    }

    @Test
    func test_resolveLatestVersion_malformedShaInOutput_throwsHeadRefNotFound() async throws {
        let runner = SubprocessOutputRunnerMock()
        runner.results = [(0, "not-a-sha\tHEAD\n")]
        let sut = SkillLatestVersionResolver(outputRunner: runner)

        await #expect(throws: SkillLatestVersionResolver.SkillLatestVersionResolverError.headRefNotFound(repository: "owner/repo")) {
            try await sut.resolveLatestVersion(repository: "owner/repo")
        }
    }
}
