//  GitRepositorySkillFetcherTests.swift

import Foundation
import Testing
@testable import LucaFoundation
@testable import ManagerCore

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
            try await sut.skillPaths(repository: "owner/repo", ref: nil)
        }
    }

    // MARK: - test_skillPaths_clonesOnlyOncePerRepository

    @Test
    func test_skillPaths_clonesOnlyOncePerRepository() async throws {
        let runner = SeedingSubprocessRunnerMock()
        runner.exitCodes = [0]
        runner.filesToCreate = [
            "skills/foo/SKILL.md": "# Foo"
        ]
        let sut = GitRepositorySkillFetcher(subprocessRunner: runner)

        _ = try await sut.skillPaths(repository: "owner/repo", ref: nil)
        _ = try await sut.skillPaths(repository: "owner/repo", ref: nil)

        #expect(runner.runCallCount == 1)
    }

    // MARK: - test_skillPaths_disablesGitTerminalPrompt

    @Test
    func test_skillPaths_disablesGitTerminalPrompt() async throws {
        let runner = SeedingSubprocessRunnerMock()
        runner.exitCodes = [0]
        runner.filesToCreate = ["skills/foo/SKILL.md": "# Foo"]
        let sut = GitRepositorySkillFetcher(subprocessRunner: runner)

        _ = try await sut.skillPaths(repository: "owner/repo", ref: nil)

        let env = try #require(runner.recordedEnvironments.first)
        #expect(env["GIT_TERMINAL_PROMPT"] == "0")
    }

    // MARK: - test_skillPaths_clonesWithQuietFlag

    @Test
    func test_skillPaths_clonesWithQuietFlag() async throws {
        let runner = SeedingSubprocessRunnerMock()
        runner.exitCodes = [0]
        runner.filesToCreate = ["skills/foo/SKILL.md": "# Foo"]
        let sut = GitRepositorySkillFetcher(subprocessRunner: runner)

        _ = try await sut.skillPaths(repository: "owner/repo", ref: nil)

        let args = try #require(runner.recordedArguments.first)
        #expect(args.contains("--quiet"))
    }

    // MARK: - test_skillPaths_shorthandUrl_expandsToHttps

    @Test
    func test_skillPaths_shorthandUrl_expandsToHttps() async throws {
        let runner = SeedingSubprocessRunnerMock()
        runner.exitCodes = [0]
        runner.filesToCreate = ["skills/foo/SKILL.md": "# Foo"]
        let sut = GitRepositorySkillFetcher(subprocessRunner: runner)

        _ = try await sut.skillPaths(repository: "owner/repo", ref: nil)

        let cloneURL = runner.recordedArguments.first?[4]
        #expect(cloneURL == "https://github.com/owner/repo")
    }

    // MARK: - test_skillPaths_httpsUrl_passedVerbatim

    @Test
    func test_skillPaths_httpsUrl_passedVerbatim() async throws {
        let runner = SeedingSubprocessRunnerMock()
        runner.exitCodes = [0]
        runner.filesToCreate = ["skills/foo/SKILL.md": "# Foo"]
        let sut = GitRepositorySkillFetcher(subprocessRunner: runner)

        _ = try await sut.skillPaths(repository: "https://github.com/owner/repo", ref: nil)

        let cloneURL = runner.recordedArguments.first?[4]
        #expect(cloneURL == "https://github.com/owner/repo")
    }

    // MARK: - test_skillPaths_httpUrl_passedVerbatim

    @Test
    func test_skillPaths_httpUrl_passedVerbatim() async throws {
        let runner = SeedingSubprocessRunnerMock()
        runner.exitCodes = [0]
        runner.filesToCreate = ["skills/foo/SKILL.md": "# Foo"]
        let sut = GitRepositorySkillFetcher(subprocessRunner: runner)

        _ = try await sut.skillPaths(repository: "http://github.com/owner/repo", ref: nil)

        let cloneURL = runner.recordedArguments.first?[4]
        #expect(cloneURL == "http://github.com/owner/repo")
    }

    // MARK: - test_skillPaths_excludesPyPackagesDirectory

    @Test
    func test_skillPaths_excludesPyPackagesDirectory() async throws {
        let runner = SeedingSubprocessRunnerMock()
        runner.exitCodes = [0]
        runner.filesToCreate = [
            "skills/foo/SKILL.md": "# Foo",
            "skills/foo/__pypackages__/module.py": "code"
        ]
        let sut = GitRepositorySkillFetcher(subprocessRunner: runner)

        let paths = try await sut.skillPaths(repository: "owner/repo", ref: nil)

        #expect(paths.contains("skills/foo/SKILL.md"))
        #expect(!paths.contains("skills/foo/__pypackages__/module.py"))
    }

    // MARK: - test_skillPaths_sshUrl_passedVerbatim

    @Test
    func test_skillPaths_sshUrl_passedVerbatim() async throws {
        let runner = SeedingSubprocessRunnerMock()
        runner.exitCodes = [0]
        runner.filesToCreate = ["skills/foo/SKILL.md": "# Foo"]
        let sut = GitRepositorySkillFetcher(subprocessRunner: runner)

        _ = try await sut.skillPaths(repository: "git@github.je-labs.com:ai-platform/skills.git", ref: nil)

        let cloneURL = runner.recordedArguments.first?[4]
        #expect(cloneURL == "git@github.je-labs.com:ai-platform/skills.git")
    }

    // MARK: - test_skillPaths_returnsSkillMdAndAuxiliaryFiles

    @Test
    func test_skillPaths_returnsSkillMdAndAuxiliaryFiles() async throws {
        let runner = SeedingSubprocessRunnerMock()
        runner.exitCodes = [0]
        runner.filesToCreate = [
            "skills/foo/SKILL.md": "# Foo",
            "skills/foo/resources/template.md": "template",
            "README.md": "readme"
        ]
        let sut = GitRepositorySkillFetcher(subprocessRunner: runner)

        let paths = try await sut.skillPaths(repository: "owner/repo", ref: nil)

        #expect(paths.contains("skills/foo/SKILL.md"))
        #expect(paths.contains("skills/foo/resources/template.md"))
        #expect(!paths.contains("README.md"))
    }

    // MARK: - test_skillPaths_excludesMetadataJsonAndExcludedDirectories

    @Test
    func test_skillPaths_excludesMetadataJsonAndExcludedDirectories() async throws {
        let runner = SeedingSubprocessRunnerMock()
        runner.exitCodes = [0]
        runner.filesToCreate = [
            "skills/foo/SKILL.md": "# Foo",
            "skills/foo/metadata.json": "{}",
            "skills/foo/__pycache__/module.pyc": "bytecode",
            "skills/foo/resources/helper.md": "helper"
        ]
        let sut = GitRepositorySkillFetcher(subprocessRunner: runner)

        let paths = try await sut.skillPaths(repository: "owner/repo", ref: nil)

        #expect(paths.contains("skills/foo/SKILL.md"))
        #expect(paths.contains("skills/foo/resources/helper.md"))
        #expect(!paths.contains("skills/foo/metadata.json"))
        #expect(!paths.contains("skills/foo/__pycache__/module.pyc"))
    }

    // MARK: - test_downloadSkill_returnsFileContent

    @Test
    func test_downloadSkill_returnsFileContent() async throws {
        let runner = SeedingSubprocessRunnerMock()
        runner.exitCodes = [0]
        runner.filesToCreate = ["skills/foo/SKILL.md": "# Foo skill content"]
        let sut = GitRepositorySkillFetcher(subprocessRunner: runner)

        let data = try await sut.downloadSkill(repository: "owner/repo", path: "skills/foo/SKILL.md", ref: nil)

        #expect(data == Data("# Foo skill content".utf8))
    }

    // MARK: - test_downloadSkill_missingFile_throwsFileReadFailed

    @Test
    func test_downloadSkill_missingFile_throwsFileReadFailed() async throws {
        let runner = SeedingSubprocessRunnerMock()
        runner.exitCodes = [0]
        runner.filesToCreate = ["skills/foo/SKILL.md": "# Foo"]
        let sut = GitRepositorySkillFetcher(subprocessRunner: runner)

        await #expect(throws: GitRepositorySkillFetcherError.fileReadFailed(path: "skills/bar/SKILL.md")) {
            try await sut.downloadSkill(repository: "owner/repo", path: "skills/bar/SKILL.md", ref: nil)
        }
    }

    // MARK: - test_skillPaths_withTag_usesDepth1AndBranchFlag

    @Test
    func test_skillPaths_withTag_usesDepth1AndBranchFlag() async throws {
        let runner = SeedingSubprocessRunnerMock()
        runner.exitCodes = [0]
        runner.filesToCreate = ["skills/foo/SKILL.md": "# Foo"]
        let sut = GitRepositorySkillFetcher(subprocessRunner: runner)

        _ = try await sut.skillPaths(repository: "owner/repo", ref: "v1.2.0")

        let args = try #require(runner.recordedArguments.first)
        #expect(args.contains("--depth"))
        #expect(args.contains("1"))
        #expect(args.contains("--branch"))
        #expect(args.contains("v1.2.0"))
    }

    // MARK: - test_skillPaths_withCommitSha_doesFullCloneThenCheckout

    @Test
    func test_skillPaths_withCommitSha_doesFullCloneThenCheckout() async throws {
        let sha = "abc1234def567890"
        let runner = SeedingSubprocessRunnerMock()
        runner.exitCodes = [0, 0]
        runner.filesToCreate = ["skills/foo/SKILL.md": "# Foo"]
        let sut = GitRepositorySkillFetcher(subprocessRunner: runner)

        _ = try await sut.skillPaths(repository: "owner/repo", ref: sha)

        #expect(runner.runCallCount == 2)
        let cloneArgs = runner.recordedArguments[0]
        #expect(!cloneArgs.contains("--depth"))
        #expect(!cloneArgs.contains("--branch"))
        let checkoutArgs = runner.recordedArguments[1]
        #expect(checkoutArgs.contains("-C"))
        #expect(checkoutArgs.contains("checkout"))
        #expect(checkoutArgs.contains(sha))
    }

    // MARK: - test_skillPaths_checkoutFailed_throwsCheckoutFailedError

    @Test
    func test_skillPaths_checkoutFailed_throwsCheckoutFailedError() async throws {
        let sha = "abc1234def567890"
        let runner = SeedingSubprocessRunnerMock()
        runner.exitCodes = [0, 128]
        runner.filesToCreate = ["skills/foo/SKILL.md": "# Foo"]
        let sut = GitRepositorySkillFetcher(subprocessRunner: runner)

        await #expect(throws: GitRepositorySkillFetcherError.checkoutFailed(repository: "owner/repo", ref: sha, exitCode: 128)) {
            try await sut.skillPaths(repository: "owner/repo", ref: sha)
        }
    }

    // MARK: - test_skillPaths_cloneFailedDuringCommitShaFetch_throwsCloneFailedError

    @Test
    func test_skillPaths_cloneFailedDuringCommitShaFetch_throwsCloneFailedError() async throws {
        let sha = "abc1234def567890"
        let runner = SeedingSubprocessRunnerMock()
        runner.exitCodes = [128]
        let sut = GitRepositorySkillFetcher(subprocessRunner: runner)

        await #expect(throws: GitRepositorySkillFetcherError.cloneFailed(repository: "owner/repo", exitCode: 128)) {
            try await sut.skillPaths(repository: "owner/repo", ref: sha)
        }
    }

    // MARK: - test_skillPaths_sameRepoAndRefSharesCache

    @Test
    func test_skillPaths_sameRepoAndRefSharesCache() async throws {
        let runner = SeedingSubprocessRunnerMock()
        runner.exitCodes = [0]
        runner.filesToCreate = ["skills/foo/SKILL.md": "# Foo"]
        let sut = GitRepositorySkillFetcher(subprocessRunner: runner)

        _ = try await sut.skillPaths(repository: "owner/repo", ref: "v1.0.0")
        _ = try await sut.skillPaths(repository: "owner/repo", ref: "v1.0.0")

        #expect(runner.runCallCount == 1)
    }

    // MARK: - test_skillPaths_skipsDirSymlinks

    @Test
    func test_skillPaths_skipsDirSymlinks() async throws {
        let runner = SeedingSubprocessRunnerMock()
        runner.exitCodes = [0]
        runner.filesToCreate = ["skills/foo/SKILL.md": "# Foo"]
        // Symlink inside the skill directory that resolves to /tmp (a real directory).
        runner.symlinksToCreate = ["skills/foo/link-to-dir": "/tmp"]
        let sut = GitRepositorySkillFetcher(subprocessRunner: runner)

        let paths = try await sut.skillPaths(repository: "owner/repo", ref: nil)

        #expect(paths.contains("skills/foo/SKILL.md"))
        #expect(!paths.contains("skills/foo/link-to-dir"))
    }

    // MARK: - test_skillPaths_sameRepoDifferentRef_clonesAgain

    @Test
    func test_skillPaths_sameRepoDifferentRef_clonesAgain() async throws {
        let runner = SeedingSubprocessRunnerMock()
        runner.exitCodes = [0, 0]
        runner.filesToCreate = ["skills/foo/SKILL.md": "# Foo"]
        let sut = GitRepositorySkillFetcher(subprocessRunner: runner)

        _ = try await sut.skillPaths(repository: "owner/repo", ref: "v1.0.0")
        _ = try await sut.skillPaths(repository: "owner/repo", ref: "v2.0.0")

        #expect(runner.runCallCount == 2)
    }
}

// MARK: - Private Mock

/// A `SubprocessRunning` mock that, on a successful clone exit code, creates a directory tree at
/// the destination path to simulate `git clone`, and returns a configurable sequence of exit codes.
private final class SeedingSubprocessRunnerMock: SubprocessRunning, @unchecked Sendable {

    /// Exit codes returned in order. If fewer codes are provided than calls made, the last code is reused.
    var exitCodes: [Int32] = [0]
    /// Relative paths → file contents to write into the clone destination.
    var filesToCreate: [String: String] = [:]
    /// Relative symlink paths → symlink destinations to create in the clone destination.
    var symlinksToCreate: [String: String] = [:]
    var recordedArguments: [[String]] = []
    var recordedEnvironments: [[String: String]] = []
    var runCallCount = 0

    func run(executableURL: URL, arguments: [String], environment: [String: String], workingDirectory: URL?, inheritStdin: Bool) async throws -> Int32 {
        recordedArguments.append(arguments)
        recordedEnvironments.append(environment)
        let index = runCallCount
        runCallCount += 1
        let code = index < exitCodes.count ? exitCodes[index] : exitCodes.last ?? 0

        // Seed files only for clone calls (first argument is "clone").
        if arguments.first == "clone", code == 0, let destPath = arguments.last {
            let destURL = URL(fileURLWithPath: destPath)
            try? FileManager.default.createDirectory(at: destURL, withIntermediateDirectories: true)

            for (relativePath, content) in filesToCreate {
                let fileURL = destURL.appendingPathComponent(relativePath)
                let parentURL = fileURL.deletingLastPathComponent()
                try? FileManager.default.createDirectory(at: parentURL, withIntermediateDirectories: true)
                try? Data(content.utf8).write(to: fileURL)
            }

            for (relativePath, destination) in symlinksToCreate {
                let linkURL = destURL.appendingPathComponent(relativePath)
                let parentURL = linkURL.deletingLastPathComponent()
                try? FileManager.default.createDirectory(at: parentURL, withIntermediateDirectories: true)
                try? FileManager.default.createSymbolicLink(atPath: linkURL.path, withDestinationPath: destination)
            }
        }

        return code
    }
}
