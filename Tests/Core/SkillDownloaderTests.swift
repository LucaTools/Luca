//  SkillDownloaderTests.swift

import Foundation
import Testing
@testable import LucaCore

struct SkillDownloaderTests {

    // MARK: - test_download_allSkills

    @Test
    func test_download_allSkills() async throws {
        let client = MultiSkillGitHubClientMock()
        client.skillPathsResult = .success([
            "skills/foo/SKILL.md",
            "skills/bar/SKILL.md"
        ])
        client.downloadResults = [
            "skills/foo/SKILL.md": Data("foo content".utf8),
            "skills/bar/SKILL.md": Data("bar content".utf8)
        ]
        let sut = SkillDownloader(gitHubClient: client)
        let skillSet = SkillSet(repository: "owner/repo", skills: [])

        let results = try await sut.download(skillSet: skillSet)

        #expect(results.count == 2)
        let names = results.map(\.name)
        #expect(names.contains("foo"))
        #expect(names.contains("bar"))
    }

    // MARK: - test_download_filteredByName

    @Test
    func test_download_filteredByName() async throws {
        let client = MultiSkillGitHubClientMock()
        client.skillPathsResult = .success([
            "skills/foo/SKILL.md",
            "skills/bar/SKILL.md",
            "skills/baz/SKILL.md"
        ])
        client.downloadResults = [
            "skills/foo/SKILL.md": Data("foo content".utf8),
            "skills/bar/SKILL.md": Data("bar content".utf8),
            "skills/baz/SKILL.md": Data("baz content".utf8)
        ]
        let sut = SkillDownloader(gitHubClient: client)
        let skillSet = SkillSet(repository: "owner/repo", skills: ["foo", "baz"])

        let results = try await sut.download(skillSet: skillSet)

        #expect(results.count == 2)
        let names = results.map(\.name)
        #expect(names.contains("foo"))
        #expect(names.contains("baz"))
        #expect(!names.contains("bar"))
    }

    // MARK: - test_download_skillNotFound

    @Test
    func test_download_skillNotFound() async throws {
        let client = MultiSkillGitHubClientMock()
        client.skillPathsResult = .success([
            "skills/foo/SKILL.md"
        ])
        client.downloadResults = [
            "skills/foo/SKILL.md": Data("foo content".utf8)
        ]
        let sut = SkillDownloader(gitHubClient: client)
        let skillSet = SkillSet(repository: "owner/repo", skills: ["missing-skill"])

        await #expect(throws: SkillDownloader.SkillDownloaderError.skillNotFound(name: "missing-skill", repository: "owner/repo")) {
            try await sut.download(skillSet: skillSet)
        }
    }

    // MARK: - test_download_repositoryNotFound

    @Test
    func test_download_repositoryNotFound() async throws {
        let client = MultiSkillGitHubClientMock()
        client.skillPathsResult = .failure(GitHubSkillTreeClient.GitHubSkillTreeClientError.unexpectedResponse(statusCode: 404))
        let sut = SkillDownloader(gitHubClient: client)
        let skillSet = SkillSet(repository: "owner/missing-repo", skills: [])

        await #expect(throws: SkillDownloader.SkillDownloaderError.repositoryNotFound("owner/missing-repo")) {
            try await sut.download(skillSet: skillSet)
        }
    }

    // MARK: - test_download_rateLimitExceeded

    @Test
    func test_download_rateLimitExceeded() async throws {
        let client = MultiSkillGitHubClientMock()
        client.skillPathsResult = .failure(GitHubSkillTreeClient.GitHubSkillTreeClientError.unexpectedResponse(statusCode: 403))
        let sut = SkillDownloader(gitHubClient: client)
        let skillSet = SkillSet(repository: "owner/repo", skills: [])

        await #expect(throws: SkillDownloader.SkillDownloaderError.rateLimitExceeded) {
            try await sut.download(skillSet: skillSet)
        }
    }

    // MARK: - test_download_noSkillsFound

    @Test
    func test_download_noSkillsFound() async throws {
        let client = MultiSkillGitHubClientMock()
        client.skillPathsResult = .success([])
        let sut = SkillDownloader(gitHubClient: client)
        let skillSet = SkillSet(repository: "owner/repo", skills: [])

        await #expect(throws: SkillDownloader.SkillDownloaderError.noSkillsFound(repository: "owner/repo")) {
            try await sut.download(skillSet: skillSet)
        }
    }

    // MARK: - test_download_invalidRepository

    @Test
    func test_download_invalidRepository() async throws {
        let client = MultiSkillGitHubClientMock()
        let sut = SkillDownloader(gitHubClient: client)
        let skillSet = SkillSet(repository: "not-a-valid-repo-string", skills: [])

        await #expect(throws: SkillDownloader.SkillDownloaderError.invalidRepository("not-a-valid-repo-string")) {
            try await sut.download(skillSet: skillSet)
        }
    }

    // MARK: - test_download_rootSkillMd_usesNameFromFrontmatter

    @Test
    func test_download_rootSkillMd_usesNameFromFrontmatter() async throws {
        let client = MultiSkillGitHubClientMock()
        client.skillPathsResult = .success(["SKILL.md"])
        let skillContent = """
        ---
        name: my-root-skill
        description: A root skill
        ---

        # Root skill content
        """.data(using: .utf8)!
        client.downloadResults = ["SKILL.md": skillContent]
        let sut = SkillDownloader(gitHubClient: client)
        let skillSet = SkillSet(repository: "owner/repo", skills: [])

        let results = try await sut.download(skillSet: skillSet)

        #expect(results.count == 1)
        #expect(results[0].name == "my-root-skill")
        #expect(results[0].content == skillContent)
    }

    // MARK: - test_download_httpsUrl_parsesOwnerRepo

    @Test
    func test_download_httpsUrl_parsesOwnerRepo() async throws {
        let client = MultiSkillGitHubClientMock()
        client.skillPathsResult = .success(["skills/foo/SKILL.md"])
        client.downloadResults = ["skills/foo/SKILL.md": Data("foo".utf8)]
        let sut = SkillDownloader(gitHubClient: client)
        let skillSet = SkillSet(repository: "https://github.com/owner/repo", skills: [])

        let results = try await sut.download(skillSet: skillSet)

        #expect(results.count == 1)
        #expect(client.lastOwner == "owner")
        #expect(client.lastRepo == "repo")
    }

    // MARK: - test_download_httpsUrlWithGitSuffix_parsesOwnerRepo

    @Test
    func test_download_httpsUrlWithGitSuffix_parsesOwnerRepo() async throws {
        let client = MultiSkillGitHubClientMock()
        client.skillPathsResult = .success(["skills/bar/SKILL.md"])
        client.downloadResults = ["skills/bar/SKILL.md": Data("bar".utf8)]
        let sut = SkillDownloader(gitHubClient: client)
        let skillSet = SkillSet(repository: "https://github.com/owner/repo.git", skills: [])

        let results = try await sut.download(skillSet: skillSet)

        #expect(results.count == 1)
        #expect(client.lastOwner == "owner")
        #expect(client.lastRepo == "repo")
    }
}

// MARK: - Private Mock

private final class MultiSkillGitHubClientMock: GitHubSkillTreeFetching, @unchecked Sendable {

    var skillPathsResult: Result<[String], Error> = .success([])
    var downloadResults: [String: Data] = [:]
    var lastOwner: String?
    var lastRepo: String?

    func skillPaths(owner: String, repo: String) async throws -> [String] {
        lastOwner = owner
        lastRepo = repo
        return try skillPathsResult.get()
    }

    func downloadSkill(owner: String, repo: String, path: String) async throws -> Data {
        guard let data = downloadResults[path] else {
            throw GitHubSkillTreeClient.GitHubSkillTreeClientError.unexpectedResponse(statusCode: 404)
        }
        return data
    }
}
