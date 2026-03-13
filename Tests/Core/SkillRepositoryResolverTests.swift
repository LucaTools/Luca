//  SkillRepositoryResolverTests.swift

import Foundation
import Testing
@testable import LucaCore

struct SkillRepositoryResolverTests {

    private let resolver = SkillRepositoryResolver()

    @Test(arguments: [
        "owner/repo",
        "vercel-labs/agent-skills",
        "https://github.com/vercel-labs/agent-skills.git",
        "https://github.je-labs.com/ai-platform/skills.git",
        "git@github.je-labs.com:ai-platform/skills.git"
    ])
    func test_resolve_returnsRepositoryAsIs(repository: String) {
        let result = resolver.resolve(repository)
        #expect(result == repository)
    }
}
