//  InstalledSkillsLister.swift

import Foundation

/// Lists all skills installed in the project-local skills cache.
public struct InstalledSkillsLister {

    private let fileManager: InstalledSkillsListerFileManaging

    public init(fileManager: InstalledSkillsListerFileManaging) {
        self.fileManager = fileManager
    }

    /// Returns a sorted list of installed skill names.
    /// - Parameter isGlobal: When `true`, lists from `~/.luca/skills/`; otherwise lists from `.luca/skills/` in CWD.
    public func installedSkills(isGlobal: Bool = false) throws -> [String] {
        let skillsFolder = isGlobal ? fileManager.globalSkillsCacheFolder : fileManager.skillsCacheFolder

        guard fileManager.fileExists(atPath: skillsFolder.path) else {
            return []
        }

        let entries = try fileManager.contentsOfDirectory(at: skillsFolder, includingPropertiesForKeys: nil, options: .skipsHiddenFiles)

        var result: [String] = []

        for entry in entries {
            if let attributes = try? fileManager.attributesOfItem(atPath: entry.path),
               let type = attributes[.type] as? FileAttributeType,
               type == .typeDirectory {
                result.append(entry.lastPathComponent)
            }
        }

        return result.sorted()
    }
}
