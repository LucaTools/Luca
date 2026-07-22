//  SpecLoaderTests.swift

import Foundation
import Testing
@testable import LucaFoundation

struct SpecLoaderTests {

    @Test
    func test_loadSpec_validYAML_returnsSpec() throws {
        let sut = SpecLoader(fileManager: .default)

        let bundle = Bundle.module
        let path = try #require(bundle.url(forResource: "Lucafile_valid", withExtension: "yml"))

        let spec = try sut.loadSpec(at: path)
        let tools = try #require(spec.tools)

        #expect(tools.count == 4)
        #expect(tools[0].name == "FirebaseCLI")
        #expect(tools[1].name == "PackageGenerator")
        #expect(tools[2].name == "Sourcery")
        #expect(tools[3].name == "ToggleGen")
    }

    @Test
    func test_loadSpec_missingFile_throwsMissingSpec() throws {
        let sut = SpecLoader(fileManager: .default)

        let path = URL(fileURLWithPath: "/nonexistent/path/to/Lucafile")

        #expect {
            try sut.loadSpec(at: path)
        } throws: { error in
            guard let specError = error as? SpecLoader.SpecLoaderError,
                  case SpecLoader.SpecLoaderError.missingSpec = specError else { return false }
            return true
        }
    }

    @Test
    func test_loadSpec_invalidYAML_throwsInvalidSpec() throws {
        let sut = SpecLoader(fileManager: .default)

        let bundle = Bundle.module
        let path = try #require(bundle.url(forResource: "Lucafile_invalid", withExtension: "yml"))

        #expect {
            try sut.loadSpec(at: path)
        } throws: { error in
            guard let specError = error as? SpecLoader.SpecLoaderError,
                  case SpecLoader.SpecLoaderError.invalidSpec = specError else { return false }
            return true
        }
    }

    @Test
    func test_loadSpec_withRepos_resolvesAliasesInSkills() throws {
        let sut = SpecLoader(fileManager: .default)

        let bundle = Bundle.module
        let path = try #require(bundle.url(forResource: "Lucafile_mock_with_repos", withExtension: "yml"))

        let spec = try sut.loadSpec(at: path)
        let skills = try #require(spec.skills)

        #expect(skills.count == 4)
        #expect(skills[0].name == "frontend-design")
        #expect(skills[0].repository == "vercel-labs/agent-skills")
        #expect(skills[1].name == "skill-creator")
        #expect(skills[1].repository == "vercel-labs/agent-skills")
        #expect(skills[2].name == "swift-testing-expert")
        #expect(skills[2].repository == "git@github.com:AvdLee/Swift-Testing-Agent-Skill.git")
        #expect(skills[3].name == "swift-concurrency")
        #expect(skills[3].repository == "https://github.com/AvdLee/Swift-Concurrency-Agent-Skill.git")
    }

    @Test
    func test_loadSpec_withRepos_unknownRepositoryValueUsedVerbatim() throws {
        let sut = SpecLoader(fileManager: .default)

        let bundle = Bundle.module
        let path = try #require(bundle.url(forResource: "Lucafile_mock_with_repos", withExtension: "yml"))

        let spec = try sut.loadSpec(at: path)
        let skills = try #require(spec.skills)

        // The direct URL (not an alias key) must pass through unchanged
        let directSkill = try #require(skills.first(where: { $0.name == "swift-concurrency" }))
        #expect(directSkill.repository == "https://github.com/AvdLee/Swift-Concurrency-Agent-Skill.git")
    }

    @Test
    func test_loadSpec_skillMissingVersion_throwsInvalidSpec() throws {
        let sut = SpecLoader(fileManager: .default)
        let bundle = Bundle.module
        let path = try #require(bundle.url(forResource: "Lucafile_mock_skills_missing_version", withExtension: "yml"))

        #expect {
            try sut.loadSpec(at: path)
        } throws: { error in
            guard let specError = error as? SpecLoader.SpecLoaderError,
                  case SpecLoader.SpecLoaderError.invalidSpec = specError else { return false }
            return true
        }
    }

    @Test
    func test_loadSpec_repoWithVersion_skillInheritsRepoVersion() throws {
        let sut = SpecLoader(fileManager: .default)
        let bundle = Bundle.module
        let path = try #require(bundle.url(forResource: "Lucafile_mock_with_repo_version", withExtension: "yml"))

        let spec = try sut.loadSpec(at: path)
        let skills = try #require(spec.skills)

        // Both skills referencing the "vercel" alias (object form with version: v2.0.0) should inherit that version.
        let frontendDesign = try #require(skills.first(where: { $0.name == "frontend-design" }))
        #expect(frontendDesign.version == "v2.0.0")
        let skillCreator = try #require(skills.first(where: { $0.name == "skill-creator" }))
        #expect(skillCreator.version == "v2.0.0")

        // The skill with its own version overrides the repo default.
        let swiftTesting = try #require(skills.first(where: { $0.name == "swift-testing-expert" }))
        #expect(swiftTesting.version == "v1.5.0")
    }

    @Test
    func test_loadSpec_repoAliasWithoutVersion_skillMissingVersion_throwsInvalidSpec() throws {
        let sut = SpecLoader(fileManager: .default)
        let bundle = Bundle.module
        let path = try #require(bundle.url(forResource: "Lucafile_mock_repo_alias_missing_version", withExtension: "yml"))

        #expect {
            try sut.loadSpec(at: path)
        } throws: { error in
            guard let specError = error as? SpecLoader.SpecLoaderError,
                  case SpecLoader.SpecLoaderError.invalidSpec = specError else { return false }
            return true
        }
    }

    @Test
    func test_loadSpec_invalidYAML_errorDescriptionIsReadable() throws {
        let sut = SpecLoader(fileManager: .default)

        let bundle = Bundle.module
        let path = try #require(bundle.url(forResource: "Lucafile_invalid", withExtension: "yml"))

        #expect {
            try sut.loadSpec(at: path)
        } throws: { error in
            guard let specError = error as? SpecLoader.SpecLoaderError,
                  case SpecLoader.SpecLoaderError.invalidSpec = specError,
                  let description = specError.errorDescription else { return false }
            return !description.contains("NSUnderlyingError") && !description.contains("Error Domain=")
        }
    }
}
