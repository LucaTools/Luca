//  SkillFrontmatterParsing.swift

import Foundation

/// Parsing interface for ``SkillFrontmatterParser``.
protocol SkillFrontmatterParsing {
    func skillName(from content: Data) throws -> String
}
