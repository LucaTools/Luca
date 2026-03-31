//  GitHubSkillTreeClientTests.swift

import Foundation
import Testing
@testable import LucaCore

struct GitHubSkillTreeClientTests {

    init() async throws {}

    // MARK: - skillPaths(owner:repo:)

    @Test
    func test_skillPaths_returnsSkillMdAndAuxiliaryFilePaths() async throws {
        let dataDownloader = DataDownloaderMock(result: .fixture(Fixture(filename: "GitHubTreeMixed", type: "json")))
        let sut = GitHubSkillTreeClient(dataDownloader: dataDownloader)
        let paths = try await sut.skillPaths(owner: "owner", repo: "repo")
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
        let paths = try await sut.skillPaths(owner: "owner", repo: "repo")
        #expect(paths.contains("skills/foo/SKILL.md"))
        #expect(paths.contains("skills/foo/resources/template.md"))
        #expect(paths.contains("skills/foo/resources/examples/sample.yaml"))
        #expect(!paths.contains("README.md"))
    }

    @Test
    func test_skillPaths_excludesMetadataJsonAndExcludedDirectories() async throws {
        let dataDownloader = DataDownloaderMock(result: .fixture(Fixture(filename: "GitHubTreeWithExcludedFiles", type: "json")))
        let sut = GitHubSkillTreeClient(dataDownloader: dataDownloader)
        let paths = try await sut.skillPaths(owner: "owner", repo: "repo")
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
            try await sut.skillPaths(owner: "owner", repo: "repo")
        }
    }

    @Test
    func test_skillPaths_decodingFailed() async throws {
        let invalidJSON = Data("not valid json".utf8)
        let dataDownloader = DataDownloaderMock(result: .rawData(invalidJSON, 200))
        let sut = GitHubSkillTreeClient(dataDownloader: dataDownloader)
        await #expect(throws: GitHubSkillTreeClientError.decodingFailed) {
            try await sut.skillPaths(owner: "owner", repo: "repo")
        }
    }

    @Test
    func test_skillPaths_treeTruncated() async throws {
        let dataDownloader = DataDownloaderMock(result: .fixture(Fixture(filename: "GitHubTreeTruncated", type: "json")))
        let sut = GitHubSkillTreeClient(dataDownloader: dataDownloader)
        await #expect(throws: GitHubSkillTreeClientError.treeTruncated) {
            try await sut.skillPaths(owner: "owner", repo: "repo")
        }
    }

    // MARK: - downloadSkill(owner:repo:path:)

    @Test
    func test_downloadSkill_returnsData() async throws {
        let expectedData = Data("# My Skill\nThis is a skill.".utf8)
        let dataDownloader = DataDownloaderMock(result: .rawData(expectedData, 200))
        let sut = GitHubSkillTreeClient(dataDownloader: dataDownloader)
        let data = try await sut.downloadSkill(owner: "owner", repo: "repo", path: "skills/my-skill/SKILL.md")
        #expect(data == expectedData)
    }

    @Test
    func test_downloadSkill_unexpectedResponse() async throws {
        let dataDownloader = DataDownloaderMock(result: .statusCode(403))
        let sut = GitHubSkillTreeClient(dataDownloader: dataDownloader)
        await #expect(throws: GitHubSkillTreeClientError.unexpectedResponse(statusCode: 403)) {
            try await sut.downloadSkill(owner: "owner", repo: "repo", path: "skills/my-skill/SKILL.md")
        }
    }
}
