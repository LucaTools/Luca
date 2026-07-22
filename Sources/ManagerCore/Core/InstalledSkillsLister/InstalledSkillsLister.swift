//  InstalledSkillsLister.swift

import Foundation

/// Lists all skills installed in the project-local or global skills cache.
public struct InstalledSkillsLister {

    private let fileManager: InstalledSkillsListerFileManaging

    public init(fileManager: InstalledSkillsListerFileManaging) {
        self.fileManager = fileManager
    }

    /// Returns a dictionary mapping installed skill names to their sorted installed versions.
    /// - Parameter isGlobal: When `true`, lists from `~/.luca/skills/`; otherwise lists from `.luca/skills/` in CWD.
    public func installedSkills(isGlobal: Bool = false) throws -> [String: [String]] {
        let skillsFolder = isGlobal ? fileManager.globalSkillsCacheFolder : fileManager.skillsCacheFolder

        guard fileManager.fileExists(atPath: skillsFolder.path) else {
            return [:]
        }

        let nameEntries = try fileManager.contentsOfDirectory(
            at: skillsFolder,
            includingPropertiesForKeys: nil,
            options: .skipsHiddenFiles
        )

        var result: [String: [String]] = [:]

        for nameEntry in nameEntries {
            guard let attributes = try? fileManager.attributesOfItem(atPath: nameEntry.path),
                  let type = attributes[.type] as? FileAttributeType,
                  type == .typeDirectory else { continue }

            let versionEntries = (try? fileManager.contentsOfDirectory(
                at: nameEntry,
                includingPropertiesForKeys: nil,
                options: .skipsHiddenFiles
            )) ?? []

            let versions: [String] = versionEntries.compactMap { versionEntry in
                guard let vAttrs = try? fileManager.attributesOfItem(atPath: versionEntry.path),
                      let vType = vAttrs[.type] as? FileAttributeType,
                      vType == .typeDirectory else { return nil }
                return versionEntry.lastPathComponent
            }.sorted()

            result[nameEntry.lastPathComponent] = versions
        }

        return result
    }
}
