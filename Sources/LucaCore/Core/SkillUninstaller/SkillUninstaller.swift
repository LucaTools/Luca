//  SkillUninstaller.swift

import Foundation

/// Removes a skill from the project-local skills cache and all agent symlinks.
public struct SkillUninstaller {

    /// Errors that can be thrown during skill uninstallation.
    public enum SkillUninstallerError: Error, LocalizedError, Equatable {
        case skillNotFound(name: String)

        public var errorDescription: String? {
            switch self {
            case .skillNotFound(let name):
                return "Skill '\(name)' is not installed."
            }
        }
    }

    private let fileManager: SkillUninstallerFileManaging
    private let printer: Printing

    public init(fileManager: SkillUninstallerFileManaging, printer: Printing) {
        self.fileManager = fileManager
        self.printer = printer
    }

    /// Removes the skill cache folder and any agent symlinks pointing to it.
    /// - Parameters:
    ///   - skillName: The name of the skill to uninstall.
    ///   - agents: The agents whose symlinks should be cleaned up.
    ///   - isGlobal: When `true`, uninstalls from the global skills cache (`~/.luca/skills/`)
    ///     and removes symlinks from each agent's resolved global skills path.
    ///     When `false` (default), uninstalls from the project-local cache.
    public func uninstall(skillName: String, agents: [AgentInfo], isGlobal: Bool = false) throws {
        let skillFolder = isGlobal
            ? fileManager.globalSkillsCacheFolder.appending(component: skillName)
            : fileManager.skillsCacheFolder.appending(component: skillName)

        guard fileManager.fileExists(atPath: skillFolder.path) else {
            throw SkillUninstallerError.skillNotFound(name: skillName)
        }

        printer.printFormatted("\(.raw("🗑️ Uninstalling skill \(skillName)..."))")

        // Remove symlinks first — before the cache folder is deleted.
        // fileExists(atPath:) follows symlinks and returns false for dangling symlinks,
        // so we must clean up agent symlinks while the target still exists.
        let homeDirectory = fileManager.homeDirectoryForCurrentUser
        for agent in agents {
            let symlinkPath: String
            if isGlobal {
                symlinkPath = agent.resolvedGlobalSkillsPath(homeDirectory: homeDirectory)
                    .appending(component: skillName)
                    .path
            } else {
                symlinkPath = URL(fileURLWithPath: fileManager.currentDirectoryPath)
                    .appending(components: agent.projectSkillsPath, skillName)
                    .path
            }
            if fileManager.fileExists(atPath: symlinkPath) {
                try fileManager.removeItem(atPath: symlinkPath)
            }
        }

        try fileManager.removeItem(at: skillFolder)

        printer.printFormatted("\(.primary("🙌 Skill \(skillName) has been uninstalled."))")
    }
}
