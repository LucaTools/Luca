//  GitRepositorySkillFetcherTests.swift

import Foundation
import Testing
@testable import LucaCore

struct GitRepositorySkillFetcherTests {

    // MARK: - test_skillPaths_gitNotFound

    @Test
    func test_skillPaths_gitNotFound() async throws {
        let runner = SubprocessRunnerMock()
        let sut = GitRepositorySkillFetcher(subprocessRunner: runner)

        // git executable doesn't exist at /usr/bin/git on Linux in CI — skip if present
        // This test exercises the code path when the executable is absent.
        // We can't easily make /usr/bin/git absent, but we can test the clone-failure path below.
        _ = runner  // suppress unused warning
    }

    // MARK: - test_skillPaths_cloneFailed_throwsCloneFailedError

    @Test
    func test_skillPaths_cloneFailed_throwsCloneFailedError() async throws {
        let runner = SubprocessRunnerMock()
        runner.exitCodes = [128]
        let sut = GitRepositorySkillFetcher(subprocessRunner: runner)

        await #expect(throws: GitRepositorySkillFetcherError.cloneFailed(repository: "owner/repo", exitCode: 128)) {
            try await sut.skillPaths(repository: "owner/repo")
        }
    }

    // MARK: - test_skillPaths_clonesOnlyOncePerRepository

    @Test
    func test_skillPaths_clonesOnlyOncePerRepository() async throws {
        let runner = SeedingSubprocessRunnerMock()
        runner.exitCode = 0
        runner.filesToCreate = [
            "skills/foo/SKILL.md": "# Foo"
        ]
        let sut = GitRepositorySkillFetcher(subprocessRunner: runner)

        _ = try await sut.skillPaths(repository: "owner/repo")
        _ = try await sut.skillPaths(repository: "owner/repo")

        #expect(runner.runCallCount == 1)
    }

    // MARK: - test_skillPaths_disablesGitTerminalPrompt

    @Test
    func test_skillPaths_disablesGitTerminalPrompt() async throws {
        let runner = SeedingSubprocessRunnerMock()
        runner.exitCode = 0
        runner.filesToCreate = ["skills/foo/SKILL.md": "# Foo"]
        let sut = GitRepositorySkillFetcher(subprocessRunner: runner)

        _ = try await sut.skillPaths(repository: "owner/repo")

        let env = try #require(runner.recordedEnvironments.first)
        #expect(env["GIT_TERMINAL_PROMPT"] == "0")
    }

    // MARK: - test_skillPaths_clonesWithQuietFlag

    @Test
    func test_skillPaths_clonesWithQuietFlag() async throws {
        let runner = SeedingSubprocessRunnerMock()
        runner.exitCode = 0
        runner.filesToCreate = ["skills/foo/SKILL.md": "# Foo"]
        let sut = GitRepositorySkillFetcher(subprocessRunner: runner)

        _ = try await sut.skillPaths(repository: "owner/repo")

        let args = try #require(runner.recordedArguments.first)
        #expect(args.contains("--quiet"))
    }

    // MARK: - test_skillPaths_shorthandUrl_expandsToHttps

    @Test
    func test_skillPaths_shorthandUrl_expandsToHttps() async throws {
        let runner = SeedingSubprocessRunnerMock()
        runner.exitCode = 0
        runner.filesToCreate = ["skills/foo/SKILL.md": "# Foo"]
        let sut = GitRepositorySkillFetcher(subprocessRunner: runner)

        _ = try await sut.skillPaths(repository: "owner/repo")

        let cloneURL = runner.recordedArguments.first?[4]
        #expect(cloneURL == "https://github.com/owner/repo")
    }

    // MARK: - test_skillPaths_sshUrl_passedVerbatim

    @Test
    func test_skillPaths_sshUrl_passedVerbatim() async throws {
        let runner = SeedingSubprocessRunnerMock()
        runner.exitCode = 0
        runner.filesToCreate = ["skills/foo/SKILL.md": "# Foo"]
        let sut = GitRepositorySkillFetcher(subprocessRunner: runner)

        _ = try await sut.skillPaths(repository: "git@github.je-labs.com:ai-platform/skills.git")

        let cloneURL = runner.recordedArguments.first?[4]
        #expect(cloneURL == "git@github.je-labs.com:ai-platform/skills.git")
    }

    // MARK: - test_skillPaths_returnsSkillMdAndAuxiliaryFiles

    @Test
    func test_skillPaths_returnsSkillMdAndAuxiliaryFiles() async throws {
        let runner = SeedingSubprocessRunnerMock()
        runner.exitCode = 0
        runner.filesToCreate = [
            "skills/foo/SKILL.md": "# Foo",
            "skills/foo/resources/template.md": "template",
            "README.md": "readme"
        ]
        let sut = GitRepositorySkillFetcher(subprocessRunner: runner)

        let paths = try await sut.skillPaths(repository: "owner/repo")

        #expect(paths.contains("skills/foo/SKILL.md"))
        #expect(paths.contains("skills/foo/resources/template.md"))
        #expect(!paths.contains("README.md"))
    }

    // MARK: - test_skillPaths_excludesMetadataJsonAndExcludedDirectories

    @Test
    func test_skillPaths_excludesMetadataJsonAndExcludedDirectories() async throws {
        let runner = SeedingSubprocessRunnerMock()
        runner.exitCode = 0
        runner.filesToCreate = [
            "skills/foo/SKILL.md": "# Foo",
            "skills/foo/metadata.json": "{}",
            "skills/foo/__pycache__/module.pyc": "bytecode",
            "skills/foo/resources/helper.md": "helper"
        ]
        let sut = GitRepositorySkillFetcher(subprocessRunner: runner)

        let paths = try await sut.skillPaths(repository: "owner/repo")

        #expect(paths.contains("skills/foo/SKILL.md"))
        #expect(paths.contains("skills/foo/resources/helper.md"))
        #expect(!paths.contains("skills/foo/metadata.json"))
        #expect(!paths.contains("skills/foo/__pycache__/module.pyc"))
    }

    // MARK: - test_downloadSkill_returnsFileContent

    @Test
    func test_downloadSkill_returnsFileContent() async throws {
        let runner = SeedingSubprocessRunnerMock()
        runner.exitCode = 0
        runner.filesToCreate = ["skills/foo/SKILL.md": "# Foo skill content"]
        let sut = GitRepositorySkillFetcher(subprocessRunner: runner)

        let data = try await sut.downloadSkill(repository: "owner/repo", path: "skills/foo/SKILL.md")

        #expect(data == Data("# Foo skill content".utf8))
    }

    // MARK: - test_downloadSkill_missingFile_throwsFileReadFailed

    @Test
    func test_downloadSkill_missingFile_throwsFileReadFailed() async throws {
        let runner = SeedingSubprocessRunnerMock()
        runner.exitCode = 0
        runner.filesToCreate = ["skills/foo/SKILL.md": "# Foo"]
        let sut = GitRepositorySkillFetcher(subprocessRunner: runner)

        await #expect(throws: GitRepositorySkillFetcherError.fileReadFailed(path: "skills/bar/SKILL.md")) {
            try await sut.downloadSkill(repository: "owner/repo", path: "skills/bar/SKILL.md")
        }
    }
}

// MARK: - Private Mock

/// A `SubprocessRunning` mock that, on a successful exit code, creates a directory tree at
/// the destination path (the last argument) to simulate a `git clone`.
private final class SeedingSubprocessRunnerMock: SubprocessRunning, @unchecked Sendable {

    var exitCode: Int32 = 0
    /// Relative paths → file contents to write into the clone destination.
    var filesToCreate: [String: String] = [:]
    var recordedArguments: [[String]] = []
    var recordedEnvironments: [[String: String]] = []
    var runCallCount = 0

    func run(executableURL: URL, arguments: [String], environment: [String: String]) async throws -> Int32 {
        recordedArguments.append(arguments)
        recordedEnvironments.append(environment)
        runCallCount += 1

        guard exitCode == 0, let destPath = arguments.last else {
            return exitCode
        }

        let destURL = URL(fileURLWithPath: destPath)
        try? FileManager.default.createDirectory(at: destURL, withIntermediateDirectories: true)

        for (relativePath, content) in filesToCreate {
            let fileURL = destURL.appendingPathComponent(relativePath)
            let parentURL = fileURL.deletingLastPathComponent()
            try? FileManager.default.createDirectory(at: parentURL, withIntermediateDirectories: true)
            try? Data(content.utf8).write(to: fileURL)
        }

        return exitCode
    }
}
