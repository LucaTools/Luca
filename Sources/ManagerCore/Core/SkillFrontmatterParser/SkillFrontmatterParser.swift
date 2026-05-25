//  SkillFrontmatterParser.swift

import Foundation
import LucaCore
import Yams

/// Parses the YAML frontmatter from SKILL.md files to extract skill metadata.
///
/// SKILL.md files contain a YAML frontmatter block at the top, delimited by `---` lines:
///
/// ```markdown
/// ---
/// name: find-skills
/// description: Helps find and discover skills
/// ---
///
/// # Skill content here...
/// ```
///
/// This parser extracts the `name` field from the frontmatter block.
struct SkillFrontmatterParser: SkillFrontmatterParsing {

    enum SkillFrontmatterParserError: Error, LocalizedError, Equatable {
        /// The frontmatter was parsed successfully but does not contain a `name` key.
        case missingNameField
        /// The frontmatter could not be found or parsed as valid YAML.
        case invalidFrontmatter

        var errorDescription: String? {
            switch self {
            case .missingNameField:
                return "Missing 'name' field in skill frontmatter"
            case .invalidFrontmatter:
                return "Invalid or missing frontmatter in skill file"
            }
        }
    }

    /// Extracts the skill name from the YAML frontmatter of the given content.
    ///
    /// - Parameter content: The raw bytes of a SKILL.md file.
    /// - Returns: The value of the `name` field from the frontmatter.
    /// - Throws: ``SkillFrontmatterParserError/invalidFrontmatter`` if the content cannot be
    ///   decoded as UTF-8 or if the frontmatter is missing or malformed.
    ///   Throws ``SkillFrontmatterParserError/missingNameField`` if the frontmatter does not
    ///   contain a `name` key.
    func skillName(from content: Data) throws -> String {
        // Convert Data to String
        guard let contentString = String(data: content, encoding: .utf8) else {
            throw SkillFrontmatterParserError.invalidFrontmatter
        }

        // Extract the frontmatter block between the first and second ---
        let lines = contentString.split(separator: "\n", omittingEmptySubsequences: false).map(String.init)

        // Find the first delimiter
        guard let firstDelimiterIndex = lines.firstIndex(where: { $0.trimmingCharacters(in: .whitespaces) == "---" }) else {
            throw SkillFrontmatterParserError.invalidFrontmatter
        }

        // Find the second delimiter after the first
        let afterFirstDelimiter = firstDelimiterIndex + 1
        guard afterFirstDelimiter < lines.count else {
            throw SkillFrontmatterParserError.invalidFrontmatter
        }

        guard let secondDelimiterIndex = lines[afterFirstDelimiter...].firstIndex(where: { $0.trimmingCharacters(in: .whitespaces) == "---" }) else {
            throw SkillFrontmatterParserError.invalidFrontmatter
        }

        // Extract the YAML content between the two delimiters
        let frontmatterLines = lines[(firstDelimiterIndex + 1)..<secondDelimiterIndex]
        let frontmatterYAML = frontmatterLines.joined(separator: "\n")

        // Parse the YAML
        let yamlObject: Any
        do {
            guard let parsed = try Yams.load(yaml: frontmatterYAML) else {
                throw SkillFrontmatterParserError.invalidFrontmatter
            }
            yamlObject = parsed
        } catch {
            throw SkillFrontmatterParserError.invalidFrontmatter
        }

        // Cast to dictionary and extract name
        guard let dict = yamlObject as? [String: Any] else {
            throw SkillFrontmatterParserError.invalidFrontmatter
        }

        guard let name = dict["name"] as? String else {
            throw SkillFrontmatterParserError.missingNameField
        }

        return name
    }
}
