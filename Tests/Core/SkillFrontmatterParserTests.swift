//  SkillFrontmatterParserTests.swift

import Foundation
import Testing
@testable import LucaFoundation
@testable import ManagerCore

struct SkillFrontmatterParserTests {

    private let sut = SkillFrontmatterParser()

    @Test
    func test_skillName_validFrontmatter_returnsName() throws {
        let content = """
        ---
        name: find-skills
        description: Helps find and discover skills
        ---

        # Skill content here...
        """.data(using: .utf8)!

        let name = try sut.skillName(from: content)

        #expect(name == "find-skills")
    }

    @Test
    func test_skillName_missingNameField_throwsMissingNameField() throws {
        let content = """
        ---
        description: Helps find and discover skills
        ---

        # Skill content here...
        """.data(using: .utf8)!

        #expect(throws: SkillFrontmatterParser.SkillFrontmatterParserError.missingNameField) {
            _ = try sut.skillName(from: content)
        }
    }

    @Test
    func test_skillName_noFrontmatter_throwsInvalidFrontmatter() throws {
        let content = """
        # No frontmatter here
        Just content
        """.data(using: .utf8)!

        #expect(throws: SkillFrontmatterParser.SkillFrontmatterParserError.invalidFrontmatter) {
            _ = try sut.skillName(from: content)
        }
    }

    @Test
    func test_skillName_invalidYaml_throwsInvalidFrontmatter() throws {
        let content = """
        ---
        name: find-skills
        description: [unclosed list
        ---

        # Skill content here...
        """.data(using: .utf8)!

        #expect(throws: SkillFrontmatterParser.SkillFrontmatterParserError.invalidFrontmatter) {
            _ = try sut.skillName(from: content)
        }
    }

    @Test
    func test_skillName_invalidUtf8_throwsInvalidFrontmatter() throws {
        let invalidBytes: [UInt8] = [0xFF, 0xFE, 0xFF]
        let content = Data(invalidBytes)

        #expect(throws: SkillFrontmatterParser.SkillFrontmatterParserError.invalidFrontmatter) {
            _ = try sut.skillName(from: content)
        }
    }

    @Test
    func test_skillName_onlyOpeningDelimiter_throwsInvalidFrontmatter() throws {
        let content = Data("---\nname: foo\nno closing delimiter".utf8)

        #expect(throws: SkillFrontmatterParser.SkillFrontmatterParserError.invalidFrontmatter) {
            _ = try sut.skillName(from: content)
        }
    }

    @Test
    func test_skillName_delimiterAtEndOfFile_throwsInvalidFrontmatter() throws {
        let content = Data("---".utf8)

        #expect(throws: SkillFrontmatterParser.SkillFrontmatterParserError.invalidFrontmatter) {
            _ = try sut.skillName(from: content)
        }
    }

    @Test
    func test_skillName_emptyFrontmatter_throwsInvalidFrontmatter() throws {
        let content = Data("---\n\n---\n\n# Content".utf8)

        #expect(throws: SkillFrontmatterParser.SkillFrontmatterParserError.invalidFrontmatter) {
            _ = try sut.skillName(from: content)
        }
    }

    @Test
    func test_skillName_yamlList_throwsInvalidFrontmatter() throws {
        let content = """
        ---
        - item1
        - item2
        ---

        # Content
        """.data(using: .utf8)!

        #expect(throws: SkillFrontmatterParser.SkillFrontmatterParserError.invalidFrontmatter) {
            _ = try sut.skillName(from: content)
        }
    }
}
