//  SkillRepositoryResolverTests.swift

import Foundation
import Testing
@testable import LucaCore

struct SkillRepositoryResolverTests {

    private let resolver = SkillRepositoryResolver()

    // MARK: - Valid inputs

    @Test(arguments: [
        "owner/repo",
        "vercel-labs/agent-skills",
        "some-org/some-repo-name"
    ])
    func test_resolve_ownerRepoShorthand_returnsAsIs(repository: String) throws {
        let result = try resolver.resolve(repository)
        #expect(result == repository)
    }

    @Test(arguments: [
        "https://github.com/vercel-labs/agent-skills.git",
        "https://github.je-labs.com/ai-platform/skills.git",
        "https://example.com/org/repo"
    ])
    func test_resolve_fullHttpsUrl_returnsAsIs(repository: String) throws {
        let result = try resolver.resolve(repository)
        #expect(result == repository)
    }

    // MARK: - Invalid inputs

    @Test(arguments: [
        "",
        "noslash",
        "owner/",
        "/repo",
        "owner/repo/extra",
        "http://github.com/owner/repo",
        "git@github.com:owner/repo.git"
    ])
    func test_resolve_invalidFormat_throws(repository: String) {
        #expect(throws: SkillRepositoryResolver.SkillRepositoryResolverError.invalidRepositoryFormat(repository)) {
            try resolver.resolve(repository)
        }
    }
}
