//  SkillDownloaderTests.swift

import Foundation
import Testing
@testable import LucaFoundation
@testable import ManagerCore

struct SkillDownloaderTests {

    // MARK: - test_download_allSkills

    @Test
    func test_download_allSkills() async throws {
        let fetcher = SkillRepositoryFetchingMock()
        fetcher.skillPathsResult = .success([
            "skills/foo/SKILL.md",
            "skills/bar/SKILL.md"
        ])
        fetcher.downloadResults = [
            "skills/foo/SKILL.md": Data("foo content".utf8),
            "skills/bar/SKILL.md": Data("bar content".utf8)
        ]
        let sut = SkillDownloader(skillFetcher: fetcher)
        let skillSet = SkillSet(repository: "owner/repo", skills: [], version: "v1.0.0")

        let results = try await sut.download(skillSet: skillSet)

        #expect(results.count == 2)
        let names = results.map(\.name)
        #expect(names.contains("foo"))
        #expect(names.contains("bar"))
        let fooFiles = try #require(results.first { $0.name == "foo" }?.files)
        #expect(fooFiles.count == 1)
        #expect(fooFiles[0].relativePath == "SKILL.md")
        #expect(fooFiles[0].content == Data("foo content".utf8))
    }

    // MARK: - test_download_filteredByName

    @Test
    func test_download_filteredByName() async throws {
        let fetcher = SkillRepositoryFetchingMock()
        fetcher.skillPathsResult = .success([
            "skills/foo/SKILL.md",
            "skills/bar/SKILL.md",
            "skills/baz/SKILL.md"
        ])
        fetcher.downloadResults = [
            "skills/foo/SKILL.md": Data("foo content".utf8),
            "skills/bar/SKILL.md": Data("bar content".utf8),
            "skills/baz/SKILL.md": Data("baz content".utf8)
        ]
        let sut = SkillDownloader(skillFetcher: fetcher)
        let skillSet = SkillSet(repository: "owner/repo", skills: ["foo", "baz"], version: "v1.0.0")

        let results = try await sut.download(skillSet: skillSet)

        #expect(results.count == 2)
        let names = results.map(\.name)
        #expect(names.contains("foo"))
        #expect(names.contains("baz"))
        #expect(!names.contains("bar"))
    }

    // MARK: - test_download_includesAuxiliaryFiles

    @Test
    func test_download_includesAuxiliaryFiles() async throws {
        let fetcher = SkillRepositoryFetchingMock()
        fetcher.skillPathsResult = .success([
            "skills/foo/SKILL.md",
            "skills/foo/resources/template.md"
        ])
        fetcher.downloadResults = [
            "skills/foo/SKILL.md": Data("foo skill".utf8),
            "skills/foo/resources/template.md": Data("template content".utf8)
        ]
        let sut = SkillDownloader(skillFetcher: fetcher)
        let skillSet = SkillSet(repository: "owner/repo", skills: [], version: "v1.0.0")

        let results = try await sut.download(skillSet: skillSet)

        #expect(results.count == 1)
        #expect(results[0].name == "foo")
        #expect(results[0].files.count == 2)
        let relativePaths = results[0].files.map(\.relativePath)
        #expect(relativePaths.contains("SKILL.md"))
        #expect(relativePaths.contains("resources/template.md"))
        let templateFile = try #require(results[0].files.first { $0.relativePath == "resources/template.md" })
        #expect(templateFile.content == Data("template content".utf8))
    }

    // MARK: - test_download_skillNotFound

    @Test
    func test_download_skillNotFound() async throws {
        let fetcher = SkillRepositoryFetchingMock()
        fetcher.skillPathsResult = .success([
            "skills/foo/SKILL.md"
        ])
        fetcher.downloadResults = [
            "skills/foo/SKILL.md": Data("foo content".utf8)
        ]
        let sut = SkillDownloader(skillFetcher: fetcher)
        let skillSet = SkillSet(repository: "owner/repo", skills: ["missing-skill"], version: "v1.0.0")

        await #expect(throws: SkillDownloader.SkillDownloaderError.skillNotFound(name: "missing-skill", repository: "owner/repo")) {
            try await sut.download(skillSet: skillSet)
        }
    }

    // MARK: - test_download_repositoryNotFound

    @Test
    func test_download_repositoryNotFound() async throws {
        let fetcher = SkillRepositoryFetchingMock()
        fetcher.skillPathsResult = .failure(GitHubSkillTreeClientError.unexpectedResponse(statusCode: 404))
        let sut = SkillDownloader(skillFetcher: fetcher)
        let skillSet = SkillSet(repository: "owner/missing-repo", skills: [], version: "v1.0.0")

        await #expect(throws: SkillDownloader.SkillDownloaderError.repositoryNotFound("owner/missing-repo")) {
            try await sut.download(skillSet: skillSet)
        }
    }

    // MARK: - test_download_rateLimitExceeded

    @Test
    func test_download_rateLimitExceeded() async throws {
        let fetcher = SkillRepositoryFetchingMock()
        fetcher.skillPathsResult = .failure(GitHubSkillTreeClientError.unexpectedResponse(statusCode: 403))
        let sut = SkillDownloader(skillFetcher: fetcher)
        let skillSet = SkillSet(repository: "owner/repo", skills: [], version: "v1.0.0")

        await #expect(throws: SkillDownloader.SkillDownloaderError.rateLimitExceeded) {
            try await sut.download(skillSet: skillSet)
        }
    }

    // MARK: - test_download_gitNotFound

    @Test
    func test_download_gitNotFound() async throws {
        let fetcher = SkillRepositoryFetchingMock()
        fetcher.skillPathsResult = .failure(GitRepositorySkillFetcherError.gitNotFound)
        let sut = SkillDownloader(skillFetcher: fetcher)
        let skillSet = SkillSet(repository: "git@github.com:owner/repo.git", skills: [], version: "v1.0.0")

        await #expect(throws: SkillDownloader.SkillDownloaderError.gitNotFound) {
            try await sut.download(skillSet: skillSet)
        }
    }

    // MARK: - test_download_cloneFailed

    @Test
    func test_download_cloneFailed() async throws {
        let fetcher = SkillRepositoryFetchingMock()
        fetcher.skillPathsResult = .failure(GitRepositorySkillFetcherError.cloneFailed(repository: "git@github.com:owner/repo.git", exitCode: 128))
        let sut = SkillDownloader(skillFetcher: fetcher)
        let skillSet = SkillSet(repository: "git@github.com:owner/repo.git", skills: [], version: "v1.0.0")

        await #expect(throws: SkillDownloader.SkillDownloaderError.cloneFailed(repository: "git@github.com:owner/repo.git")) {
            try await sut.download(skillSet: skillSet)
        }
    }

    // MARK: - test_download_checkoutFailed_mapsToCloneFailed

    @Test
    func test_download_checkoutFailed_mapsToCloneFailed() async throws {
        let fetcher = SkillRepositoryFetchingMock()
        fetcher.skillPathsResult = .failure(GitRepositorySkillFetcherError.checkoutFailed(repository: "owner/repo", ref: "abc1234", exitCode: 128))
        let sut = SkillDownloader(skillFetcher: fetcher)
        let skillSet = SkillSet(repository: "owner/repo", skills: [], version: "v1.0.0")

        await #expect(throws: SkillDownloader.SkillDownloaderError.cloneFailed(repository: "owner/repo")) {
            try await sut.download(skillSet: skillSet)
        }
    }

    // MARK: - test_download_noSkillsFound

    @Test
    func test_download_noSkillsFound() async throws {
        let fetcher = SkillRepositoryFetchingMock()
        fetcher.skillPathsResult = .success([])
        let sut = SkillDownloader(skillFetcher: fetcher)
        let skillSet = SkillSet(repository: "owner/repo", skills: [], version: "v1.0.0")

        await #expect(throws: SkillDownloader.SkillDownloaderError.noSkillsFound(repository: "owner/repo")) {
            try await sut.download(skillSet: skillSet)
        }
    }

    // MARK: - test_download_invalidRepository

    @Test
    func test_download_invalidRepository() async throws {
        let fetcher = SkillRepositoryFetchingMock()
        let sut = SkillDownloader(skillFetcher: fetcher)
        let skillSet = SkillSet(repository: "not-a-valid-repo-string", skills: [], version: "v1.0.0")

        await #expect(throws: SkillDownloader.SkillDownloaderError.invalidRepository("not-a-valid-repo-string")) {
            try await sut.download(skillSet: skillSet)
        }
    }

    // MARK: - test_download_rootSkillMd_usesNameFromFrontmatter

    @Test
    func test_download_rootSkillMd_usesNameFromFrontmatter() async throws {
        let fetcher = SkillRepositoryFetchingMock()
        fetcher.skillPathsResult = .success(["SKILL.md"])
        let skillContent = """
        ---
        name: my-root-skill
        description: A root skill
        ---

        # Root skill content
        """.data(using: .utf8)!
        fetcher.downloadResults = ["SKILL.md": skillContent]
        let sut = SkillDownloader(skillFetcher: fetcher)
        let skillSet = SkillSet(repository: "owner/repo", skills: [], version: "v1.0.0")

        let results = try await sut.download(skillSet: skillSet)

        #expect(results.count == 1)
        #expect(results[0].name == "my-root-skill")
        #expect(results[0].files[0].relativePath == "SKILL.md")
        #expect(results[0].files[0].content == skillContent)
    }

    // MARK: - test_download_sshUrl_passesRepositoryVerbatim

    @Test
    func test_download_sshUrl_passesRepositoryVerbatim() async throws {
        let fetcher = SkillRepositoryFetchingMock()
        fetcher.skillPathsResult = .success(["skills/foo/SKILL.md"])
        fetcher.downloadResults = ["skills/foo/SKILL.md": Data("foo".utf8)]
        let sut = SkillDownloader(skillFetcher: fetcher)
        let skillSet = SkillSet(repository: "git@github.com:owner/repo.git", skills: [], version: "v1.0.0")

        _ = try await sut.download(skillSet: skillSet)

        #expect(fetcher.lastRepository == "git@github.com:owner/repo.git")
    }

    // MARK: - test_download_sshUrlGitHubEnterprise_passesRepositoryVerbatim

    @Test
    func test_download_sshUrlGitHubEnterprise_passesRepositoryVerbatim() async throws {
        let fetcher = SkillRepositoryFetchingMock()
        fetcher.skillPathsResult = .success(["skills/foo/SKILL.md"])
        fetcher.downloadResults = ["skills/foo/SKILL.md": Data("foo".utf8)]
        let sut = SkillDownloader(skillFetcher: fetcher)
        let skillSet = SkillSet(repository: "git@github.je-labs.com:ai-platform/skills.git", skills: [], version: "v1.0.0")

        _ = try await sut.download(skillSet: skillSet)

        #expect(fetcher.lastRepository == "git@github.je-labs.com:ai-platform/skills.git")
    }

    // MARK: - test_download_httpsUrl_passesRepositoryVerbatim

    @Test
    func test_download_httpsUrl_passesRepositoryVerbatim() async throws {
        let fetcher = SkillRepositoryFetchingMock()
        fetcher.skillPathsResult = .success(["skills/foo/SKILL.md"])
        fetcher.downloadResults = ["skills/foo/SKILL.md": Data("foo".utf8)]
        let sut = SkillDownloader(skillFetcher: fetcher)
        let skillSet = SkillSet(repository: "https://github.com/owner/repo", skills: [], version: "v1.0.0")

        _ = try await sut.download(skillSet: skillSet)

        #expect(fetcher.lastRepository == "https://github.com/owner/repo")
    }

    // MARK: - test_download_downloadFailed

    @Test
    func test_download_downloadFailed() async throws {
        let fetcher = SkillRepositoryFetchingMock()
        fetcher.skillPathsResult = .success(["skills/foo/SKILL.md"])
        // No entry in downloadResults so the mock throws an error,
        // which SkillDownloader wraps as downloadFailed.
        let sut = SkillDownloader(skillFetcher: fetcher)
        let skillSet = SkillSet(repository: "owner/repo", skills: [], version: "v1.0.0")

        await #expect(throws: SkillDownloader.SkillDownloaderError.downloadFailed(path: "skills/foo/SKILL.md")) {
            try await sut.download(skillSet: skillSet)
        }
    }

    // MARK: - test_download_nestedSkillMd_usesNameFromFrontmatter

    @Test
    func test_download_nestedSkillMd_usesNameFromFrontmatter() async throws {
        let fetcher = SkillRepositoryFetchingMock()
        fetcher.skillPathsResult = .success(["skills/composition-patterns/SKILL.md"])
        let skillContent = """
        ---
        name: vercel-composition-patterns
        description: Composition patterns skill
        ---

        # Skill content
        """.data(using: .utf8)!
        fetcher.downloadResults = ["skills/composition-patterns/SKILL.md": skillContent]
        let sut = SkillDownloader(skillFetcher: fetcher)
        let skillSet = SkillSet(repository: "owner/repo", skills: [], version: "v1.0.0")

        let results = try await sut.download(skillSet: skillSet)

        #expect(results.count == 1)
        #expect(results[0].name == "vercel-composition-patterns")
    }

    // MARK: - test_download_nestedSkillMd_noFrontmatter_fallsBackToFolderName

    @Test
    func test_download_nestedSkillMd_noFrontmatter_fallsBackToFolderName() async throws {
        let fetcher = SkillRepositoryFetchingMock()
        fetcher.skillPathsResult = .success(["skills/my-skill/SKILL.md"])
        let skillContent = Data("# No frontmatter here\n\nJust content.".utf8)
        fetcher.downloadResults = ["skills/my-skill/SKILL.md": skillContent]
        let sut = SkillDownloader(skillFetcher: fetcher)
        let skillSet = SkillSet(repository: "owner/repo", skills: [], version: "v1.0.0")

        let results = try await sut.download(skillSet: skillSet)

        #expect(results.count == 1)
        #expect(results[0].name == "my-skill")
    }

    // MARK: - test_download_rootSkillMd_noFrontmatter_fallsBackToRepoName

    @Test
    func test_download_rootSkillMd_noFrontmatter_fallsBackToRepoName() async throws {
        let fetcher = SkillRepositoryFetchingMock()
        fetcher.skillPathsResult = .success(["SKILL.md"])
        let skillContent = Data("# No frontmatter here\n\nJust content.".utf8)
        fetcher.downloadResults = ["SKILL.md": skillContent]
        let sut = SkillDownloader(skillFetcher: fetcher)
        let skillSet = SkillSet(repository: "owner/repo", skills: [], version: "v1.0.0")

        let results = try await sut.download(skillSet: skillSet)

        #expect(results.count == 1)
        #expect(results[0].name == "repo")
        #expect(results[0].files[0].relativePath == "SKILL.md")
        #expect(results[0].files[0].content == skillContent)
    }

    // MARK: - test_download_fileReadFailed_fromSkillPaths

    @Test
    func test_download_fileReadFailed_fromSkillPaths() async throws {
        let fetcher = SkillRepositoryFetchingMock()
        fetcher.skillPathsResult = .failure(GitRepositorySkillFetcherError.fileReadFailed(path: "some/path"))
        let sut = SkillDownloader(skillFetcher: fetcher)
        let skillSet = SkillSet(repository: "git@github.com:owner/repo.git", skills: [], version: "v1.0.0")

        await #expect(throws: SkillDownloader.SkillDownloaderError.downloadFailed(path: "some/path")) {
            try await sut.download(skillSet: skillSet)
        }
    }

    // MARK: - test_download_rateLimitExceeded_429

    @Test
    func test_download_rateLimitExceeded_429() async throws {
        let fetcher = SkillRepositoryFetchingMock()
        fetcher.skillPathsResult = .failure(GitHubSkillTreeClientError.unexpectedResponse(statusCode: 429))
        let sut = SkillDownloader(skillFetcher: fetcher)
        let skillSet = SkillSet(repository: "owner/repo", skills: [], version: "v1.0.0")

        await #expect(throws: SkillDownloader.SkillDownloaderError.rateLimitExceeded) {
            try await sut.download(skillSet: skillSet)
        }
    }

    // MARK: - test_download_unexpectedStatusCode_rethrows

    @Test
    func test_download_unexpectedStatusCode_rethrows() async throws {
        let fetcher = SkillRepositoryFetchingMock()
        fetcher.skillPathsResult = .failure(GitHubSkillTreeClientError.unexpectedResponse(statusCode: 500))
        let sut = SkillDownloader(skillFetcher: fetcher)
        let skillSet = SkillSet(repository: "owner/repo", skills: [], version: "v1.0.0")

        await #expect(throws: GitHubSkillTreeClientError.unexpectedResponse(statusCode: 500)) {
            try await sut.download(skillSet: skillSet)
        }
    }

    // MARK: - test_download_nonUnexpectedResponseError_rethrows

    @Test
    func test_download_nonUnexpectedResponseError_rethrows() async throws {
        let fetcher = SkillRepositoryFetchingMock()
        fetcher.skillPathsResult = .failure(GitHubSkillTreeClientError.decodingFailed)
        let sut = SkillDownloader(skillFetcher: fetcher)
        let skillSet = SkillSet(repository: "owner/repo", skills: [], version: "v1.0.0")

        await #expect(throws: GitHubSkillTreeClientError.decodingFailed) {
            try await sut.download(skillSet: skillSet)
        }
    }

    // MARK: - test_download_invalidSshRepository_noColon

    @Test
    func test_download_invalidSshRepository_noColon() async throws {
        let fetcher = SkillRepositoryFetchingMock()
        let sut = SkillDownloader(skillFetcher: fetcher)
        let skillSet = SkillSet(repository: "git@github.com-no-colon", skills: [], version: "v1.0.0")

        await #expect(throws: SkillDownloader.SkillDownloaderError.invalidRepository("git@github.com-no-colon")) {
            try await sut.download(skillSet: skillSet)
        }
    }

    // MARK: - test_download_invalidSshRepository_missingRepo

    @Test
    func test_download_invalidSshRepository_missingRepo() async throws {
        let fetcher = SkillRepositoryFetchingMock()
        let sut = SkillDownloader(skillFetcher: fetcher)
        let skillSet = SkillSet(repository: "git@github.com:owner-only", skills: [], version: "v1.0.0")

        await #expect(throws: SkillDownloader.SkillDownloaderError.invalidRepository("git@github.com:owner-only")) {
            try await sut.download(skillSet: skillSet)
        }
    }

    // MARK: - test_download_invalidHttpsRepository_missingRepo

    @Test
    func test_download_invalidHttpsRepository_missingRepo() async throws {
        let fetcher = SkillRepositoryFetchingMock()
        let sut = SkillDownloader(skillFetcher: fetcher)
        let skillSet = SkillSet(repository: "https://github.com/owner-only", skills: [], version: "v1.0.0")

        await #expect(throws: SkillDownloader.SkillDownloaderError.invalidRepository("https://github.com/owner-only")) {
            try await sut.download(skillSet: skillSet)
        }
    }

    // MARK: - test_download_httpsUrlWithGitSuffix_extractsRepoName

    @Test
    func test_download_httpsUrlWithGitSuffix_extractsRepoName() async throws {
        let fetcher = SkillRepositoryFetchingMock()
        fetcher.skillPathsResult = .success(["SKILL.md"])
        let skillContent = Data("# No frontmatter".utf8)
        fetcher.downloadResults = ["SKILL.md": skillContent]
        let sut = SkillDownloader(skillFetcher: fetcher)
        let skillSet = SkillSet(repository: "https://github.com/owner/repo.git", skills: [], version: "v1.0.0")

        let results = try await sut.download(skillSet: skillSet)

        // Falls back to repo name extracted from HTTPS URL, stripping .git suffix
        #expect(results.count == 1)
        #expect(results[0].name == "repo")
    }

    // MARK: - test_download_httpsUrl_extractsRepoName

    @Test
    func test_download_httpsUrl_extractsRepoName() async throws {
        let fetcher = SkillRepositoryFetchingMock()
        fetcher.skillPathsResult = .success(["SKILL.md"])
        let skillContent = Data("# No frontmatter".utf8)
        fetcher.downloadResults = ["SKILL.md": skillContent]
        let sut = SkillDownloader(skillFetcher: fetcher)
        let skillSet = SkillSet(repository: "https://github.com/owner/my-repo", skills: [], version: "v1.0.0")

        let results = try await sut.download(skillSet: skillSet)

        #expect(results.count == 1)
        #expect(results[0].name == "my-repo")
    }

    // MARK: - test_download_httpUrl_extractsRepoName

    @Test
    func test_download_httpUrl_extractsRepoName() async throws {
        let fetcher = SkillRepositoryFetchingMock()
        fetcher.skillPathsResult = .success(["SKILL.md"])
        let skillContent = Data("# No frontmatter".utf8)
        fetcher.downloadResults = ["SKILL.md": skillContent]
        let sut = SkillDownloader(skillFetcher: fetcher)
        let skillSet = SkillSet(repository: "http://github.com/owner/my-repo", skills: [], version: "v1.0.0")

        let results = try await sut.download(skillSet: skillSet)

        #expect(results.count == 1)
        #expect(results[0].name == "my-repo")
    }

    // MARK: - test_download_sshUrl_extractsRepoName

    @Test
    func test_download_sshUrl_extractsRepoName() async throws {
        let fetcher = SkillRepositoryFetchingMock()
        fetcher.skillPathsResult = .success(["SKILL.md"])
        let skillContent = Data("# No frontmatter".utf8)
        fetcher.downloadResults = ["SKILL.md": skillContent]
        let sut = SkillDownloader(skillFetcher: fetcher)
        let skillSet = SkillSet(repository: "git@github.com:owner/my-repo.git", skills: [], version: "v1.0.0")

        let results = try await sut.download(skillSet: skillSet)

        // Falls back to repo name from SSH URL, stripping .git suffix
        #expect(results.count == 1)
        #expect(results[0].name == "my-repo")
    }

    // MARK: - test_download_auxiliaryFileDownloadFailed

    @Test
    func test_download_auxiliaryFileDownloadFailed() async throws {
        let fetcher = SkillRepositoryFetchingMock()
        fetcher.skillPathsResult = .success([
            "skills/foo/SKILL.md",
            "skills/foo/resources/template.md"
        ])
        // Provide SKILL.md content but NOT the auxiliary file
        fetcher.downloadResults = [
            "skills/foo/SKILL.md": Data("foo skill".utf8)
        ]
        let sut = SkillDownloader(skillFetcher: fetcher)
        let skillSet = SkillSet(repository: "owner/repo", skills: [], version: "v1.0.0")

        await #expect(throws: SkillDownloader.SkillDownloaderError.downloadFailed(path: "skills/foo/resources/template.md")) {
            try await sut.download(skillSet: skillSet)
        }
    }
}

// MARK: - Private Mock

private final class SkillRepositoryFetchingMock: SkillRepositoryFetching, @unchecked Sendable {

    var skillPathsResult: Result<[String], Error> = .success([])
    var downloadResults: [String: Data] = [:]
    var lastRepository: String?

    func skillPaths(repository: String, ref: String?) async throws -> [String] {
        lastRepository = repository
        return try skillPathsResult.get()
    }

    func downloadSkill(repository: String, path: String, ref: String?) async throws -> Data {
        guard let data = downloadResults[path] else {
            throw GitRepositorySkillFetcherError.fileReadFailed(path: path)
        }
        return data
    }
}
