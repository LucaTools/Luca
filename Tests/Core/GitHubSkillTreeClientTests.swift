//  GitHubSkillTreeClientTests.swift

import Foundation
import Testing
@testable import LucaCore

struct GitHubSkillTreeClientTests {

    init() async throws {}

    // MARK: - skillPaths(repository:)

    @Test
    func test_skillPaths_returnsSkillMdAndAuxiliaryFilePaths() async throws {
        let dataDownloader = DataDownloaderMock(result: .fixture(Fixture(filename: "GitHubTreeMixed", type: "json")))
        let sut = GitHubSkillTreeClient(dataDownloader: dataDownloader)
        let paths = try await sut.skillPaths(repository: "owner/repo")
        // SKILL.md files for each skill
        #expect(paths.contains("skills/my-skill/SKILL.md"))
        #expect(paths.contains("skills/another-skill/SKILL.md"))
        #expect(paths.contains("docs/SKILL.md"))
        // Auxiliary file inside a skill directory — must now be included
        #expect(paths.contains("skills/my-skill/example.swift"))
        // File NOT in any skill directory — must remain excluded
        #expect(!paths.contains("README.md"))
    }

    @Test
    func test_skillPaths_includesDeepNestedAuxiliaryFiles() async throws {
        let dataDownloader = DataDownloaderMock(result: .fixture(Fixture(filename: "GitHubTreeWithResources", type: "json")))
        let sut = GitHubSkillTreeClient(dataDownloader: dataDownloader)
        let paths = try await sut.skillPaths(repository: "owner/repo")
        #expect(paths.contains("skills/foo/SKILL.md"))
        #expect(paths.contains("skills/foo/resources/template.md"))
        #expect(paths.contains("skills/foo/resources/examples/sample.yaml"))
        #expect(!paths.contains("README.md"))
    }

    @Test
    func test_skillPaths_excludesMetadataJsonAndExcludedDirectories() async throws {
        let dataDownloader = DataDownloaderMock(result: .fixture(Fixture(filename: "GitHubTreeWithExcludedFiles", type: "json")))
        let sut = GitHubSkillTreeClient(dataDownloader: dataDownloader)
        let paths = try await sut.skillPaths(repository: "owner/repo")
        // Always included
        #expect(paths.contains("skills/foo/SKILL.md"))
        #expect(paths.contains("skills/foo/AGENTS.md"))
        #expect(paths.contains("skills/foo/resources/template.md"))
        // Excluded by file name
        #expect(!paths.contains("skills/foo/metadata.json"))
        // Excluded because they live inside excluded directories
        #expect(!paths.contains("skills/foo/__pycache__/module.pyc"))
        #expect(!paths.contains("skills/foo/.git/config"))
    }

    @Test
    func test_skillPaths_unexpectedResponse() async throws {
        let dataDownloader = DataDownloaderMock(result: .statusCode(404))
        let sut = GitHubSkillTreeClient(dataDownloader: dataDownloader)
        await #expect(throws: GitHubSkillTreeClientError.unexpectedResponse(statusCode: 404)) {
            try await sut.skillPaths(repository: "owner/repo")
        }
    }

    @Test
    func test_skillPaths_decodingFailed() async throws {
        let invalidJSON = Data("not valid json".utf8)
        let dataDownloader = DataDownloaderMock(result: .rawData(invalidJSON, 200))
        let sut = GitHubSkillTreeClient(dataDownloader: dataDownloader)
        await #expect(throws: GitHubSkillTreeClientError.decodingFailed) {
            try await sut.skillPaths(repository: "owner/repo")
        }
    }

    @Test
    func test_skillPaths_treeTruncated() async throws {
        let dataDownloader = DataDownloaderMock(result: .fixture(Fixture(filename: "GitHubTreeTruncated", type: "json")))
        let sut = GitHubSkillTreeClient(dataDownloader: dataDownloader)
        await #expect(throws: GitHubSkillTreeClientError.treeTruncated) {
            try await sut.skillPaths(repository: "owner/repo")
        }
    }

    // MARK: - downloadSkill(repository:path:)

    @Test
    func test_downloadSkill_returnsData() async throws {
        let expectedData = Data("# My Skill\nThis is a skill.".utf8)
        let dataDownloader = DataDownloaderMock(result: .rawData(expectedData, 200))
        let sut = GitHubSkillTreeClient(dataDownloader: dataDownloader)
        let data = try await sut.downloadSkill(repository: "owner/repo", path: "skills/my-skill/SKILL.md")
        #expect(data == expectedData)
    }

    @Test
    func test_downloadSkill_unexpectedResponse() async throws {
        let dataDownloader = DataDownloaderMock(result: .statusCode(403))
        let sut = GitHubSkillTreeClient(dataDownloader: dataDownloader)
        await #expect(throws: GitHubSkillTreeClientError.unexpectedResponse(statusCode: 403)) {
            try await sut.downloadSkill(repository: "owner/repo", path: "skills/my-skill/SKILL.md")
        }
    }

    // MARK: - SSH URL parsing

    @Test
    func test_skillPaths_sshUrl_parsesCorrectly() async throws {
        let dataDownloader = DataDownloaderMock(result: .fixture(Fixture(filename: "GitHubTreeMixed", type: "json")))
        let sut = GitHubSkillTreeClient(dataDownloader: dataDownloader)
        let paths = try await sut.skillPaths(repository: "git@github.com:owner/repo.git")
        #expect(paths.contains("skills/my-skill/SKILL.md"))
    }

    @Test
    func test_skillPaths_sshUrlWithoutGitSuffix_parsesCorrectly() async throws {
        let dataDownloader = DataDownloaderMock(result: .fixture(Fixture(filename: "GitHubTreeMixed", type: "json")))
        let sut = GitHubSkillTreeClient(dataDownloader: dataDownloader)
        let paths = try await sut.skillPaths(repository: "git@github.com:owner/repo")
        #expect(paths.contains("skills/my-skill/SKILL.md"))
    }

    @Test
    func test_skillPaths_sshUrl_invalidFormat_noColon_throws() async throws {
        let dataDownloader = DataDownloaderMock(result: .fixture(Fixture(filename: "GitHubTreeMixed", type: "json")))
        let sut = GitHubSkillTreeClient(dataDownloader: dataDownloader)
        await #expect(throws: GitHubSkillTreeClientError.invalidURL) {
            try await sut.skillPaths(repository: "git@github.com")
        }
    }

    @Test
    func test_skillPaths_sshUrl_invalidFormat_missingRepo_throws() async throws {
        let dataDownloader = DataDownloaderMock(result: .fixture(Fixture(filename: "GitHubTreeMixed", type: "json")))
        let sut = GitHubSkillTreeClient(dataDownloader: dataDownloader)
        await #expect(throws: GitHubSkillTreeClientError.invalidURL) {
            try await sut.skillPaths(repository: "git@github.com:owner")
        }
    }

    // MARK: - HTTPS URL parsing

    @Test
    func test_skillPaths_httpsUrl_parsesCorrectly() async throws {
        let dataDownloader = DataDownloaderMock(result: .fixture(Fixture(filename: "GitHubTreeMixed", type: "json")))
        let sut = GitHubSkillTreeClient(dataDownloader: dataDownloader)
        let paths = try await sut.skillPaths(repository: "https://github.com/owner/repo")
        #expect(paths.contains("skills/my-skill/SKILL.md"))
    }

    @Test
    func test_skillPaths_httpsUrlWithGitSuffix_parsesCorrectly() async throws {
        let dataDownloader = DataDownloaderMock(result: .fixture(Fixture(filename: "GitHubTreeMixed", type: "json")))
        let sut = GitHubSkillTreeClient(dataDownloader: dataDownloader)
        let paths = try await sut.skillPaths(repository: "https://github.com/owner/repo.git")
        #expect(paths.contains("skills/my-skill/SKILL.md"))
    }

    @Test
    func test_skillPaths_httpsUrl_invalidFormat_missingRepo_throws() async throws {
        let dataDownloader = DataDownloaderMock(result: .fixture(Fixture(filename: "GitHubTreeMixed", type: "json")))
        let sut = GitHubSkillTreeClient(dataDownloader: dataDownloader)
        await #expect(throws: GitHubSkillTreeClientError.invalidURL) {
            try await sut.skillPaths(repository: "https://github.com/owner")
        }
    }

    // MARK: - GitHub Enterprise Server

    @Test
    func test_skillPaths_gitHubEnterprise_usesEnterpriseApiUrl() async throws {
        let dataDownloader = DataDownloaderMock(result: .fixture(Fixture(filename: "GitHubTreeMixed", type: "json")))
        let sut = GitHubSkillTreeClient(dataDownloader: dataDownloader)
        let paths = try await sut.skillPaths(repository: "https://github.enterprise.com/owner/repo")
        #expect(paths.contains("skills/my-skill/SKILL.md"))
    }

    @Test
    func test_downloadSkill_gitHubEnterprise_usesEnterpriseRawUrl() async throws {
        let expectedData = Data("# Skill".utf8)
        let dataDownloader = DataDownloaderMock(result: .rawData(expectedData, 200))
        let sut = GitHubSkillTreeClient(dataDownloader: dataDownloader)
        let data = try await sut.downloadSkill(repository: "https://github.enterprise.com/owner/repo", path: "SKILL.md")
        #expect(data == expectedData)
    }

    @Test
    func test_downloadSkill_sshUrl_parsesCorrectly() async throws {
        let expectedData = Data("# Skill".utf8)
        let dataDownloader = DataDownloaderMock(result: .rawData(expectedData, 200))
        let sut = GitHubSkillTreeClient(dataDownloader: dataDownloader)
        let data = try await sut.downloadSkill(repository: "git@github.com:owner/repo.git", path: "SKILL.md")
        #expect(data == expectedData)
    }

    @Test
    func test_downloadSkill_gitHubEnterpriseSsh_usesEnterpriseRawUrl() async throws {
        let expectedData = Data("# Skill".utf8)
        let dataDownloader = DataDownloaderMock(result: .rawData(expectedData, 200))
        let sut = GitHubSkillTreeClient(dataDownloader: dataDownloader)
        let data = try await sut.downloadSkill(repository: "git@ghe.corp.com:owner/repo.git", path: "SKILL.md")
        #expect(data == expectedData)
    }

    // MARK: - Non-HTTP response

    @Test
    func test_skillPaths_nonHTTPResponse_throwsUnexpectedResponse() async throws {
        let dataDownloader = DataDownloaderMock(result: .nonHTTPResponse)
        let sut = GitHubSkillTreeClient(dataDownloader: dataDownloader)
        await #expect(throws: GitHubSkillTreeClientError.unexpectedResponse(statusCode: 0)) {
            try await sut.skillPaths(repository: "owner/repo")
        }
    }

    @Test
    func test_downloadSkill_nonHTTPResponse_throwsUnexpectedResponse() async throws {
        let dataDownloader = DataDownloaderMock(result: .nonHTTPResponse)
        let sut = GitHubSkillTreeClient(dataDownloader: dataDownloader)
        await #expect(throws: GitHubSkillTreeClientError.unexpectedResponse(statusCode: 0)) {
            try await sut.downloadSkill(repository: "owner/repo", path: "SKILL.md")
        }
    }

    // MARK: - Invalid shorthand

    @Test
    func test_skillPaths_invalidShorthand_throws() async throws {
        let dataDownloader = DataDownloaderMock(result: .fixture(Fixture(filename: "GitHubTreeMixed", type: "json")))
        let sut = GitHubSkillTreeClient(dataDownloader: dataDownloader)
        await #expect(throws: GitHubSkillTreeClientError.invalidURL) {
            try await sut.skillPaths(repository: "just-a-name")
        }
    }

    // MARK: - Root-level SKILL.md

    @Test
    func test_skillPaths_rootSkillMd_includedButNotAsSkillDirectory() async throws {
        let dataDownloader = DataDownloaderMock(result: .fixture(Fixture(filename: "GitHubTreeWithRootSkill", type: "json")))
        let sut = GitHubSkillTreeClient(dataDownloader: dataDownloader)
        let paths = try await sut.skillPaths(repository: "owner/repo")
        #expect(paths.contains("SKILL.md"))
        #expect(paths.contains("skills/foo/SKILL.md"))
        // Root README should not be included
        #expect(!paths.contains("README.md"))
    }
}
