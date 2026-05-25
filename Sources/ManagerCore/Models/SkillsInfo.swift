//  SkillsInfo.swift

import Foundation
import LucaFoundation

struct SkillsInfo: Codable {
    /// The agent names to install the skills for.
    let agents: [Agent]?
    /// The sets of skills to install.
    let skillSets: [SkillSet]
}
