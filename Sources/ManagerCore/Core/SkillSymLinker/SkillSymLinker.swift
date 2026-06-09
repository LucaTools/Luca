//  SkillSymLinker.swift

import Foundation
import LucaFoundation

/// Creates and manages symbolic links for installed skills.
///
/// The `SkillSymLinker` is responsible for creating symbolic links in each agent's
/// skills directory (e.g. `.claude/skills/`) that point to the canonical skill folder
/// stored in `.luca/skills/`.
///
/// This allows agents to read skills via a consistent path while Luca manages
/// the canonical skill storage.
///
/// ## Topics
///
/// ### Creating Symlinks
/// - ``setSymLink(skillName:agents:)``
struct SkillSymLinker: SkillSymLinking {

    enum SkillSymLinkerError: Error, LocalizedError, Equatable {
        case agentDirectoryCreationFailed(path: String)
        case symLinkCreationFailed(from: String, to: String)

        var errorDescription: String? {
            switch self {
            case .agentDirectoryCreationFailed(let path):
                return "Failed to create agent skills directory at \(path)."
            case .symLinkCreationFailed(let from, let to):
                return "Failed to create symbolic link from \(from) to \(to)."
            }
        }
    }

    private let fileManager: SkillSymLinkerFileManaging

    init(fileManager: SkillSymLinkerFileManaging) {
        self.fileManager = fileManager
    }

    // MARK: - Internal

    /// Creates symbolic links for a skill in each agent's skills directory.
    ///
    /// - Parameters:
    ///   - skillName: The name of the skill to symlink.
    ///   - agents: The agents for which to create symlinks.
    ///   - isGlobal: When `true`, links from `~/.luca/skills/` to each agent's global skills path.
    func setSymLink(skillName: String, agents: [AgentInfo], isGlobal: Bool = false) throws {
        let skillSource: URL
        if isGlobal {
            skillSource = fileManager.globalSkillsCacheFolder.appending(component: skillName)
        } else {
            let cwd = URL(fileURLWithPath: fileManager.currentDirectoryPath)
            skillSource = cwd.appending(components: Constants.toolFolder, Constants.skillsFolder, skillName)
        }

        for agentInfo in agents {
            let agentSkillsDir: URL
            if isGlobal {
                agentSkillsDir = agentInfo.resolvedGlobalSkillsPath(homeDirectory: fileManager.homeDirectoryForCurrentUser)
            } else {
                let cwd = URL(fileURLWithPath: fileManager.currentDirectoryPath)
                agentSkillsDir = cwd.appending(path: agentInfo.projectSkillsPath)
            }
            let symLinkDestination = agentSkillsDir.appending(component: skillName)

            do {
                try fileManager.createDirectory(at: agentSkillsDir, withIntermediateDirectories: true)
            } catch {
                throw SkillSymLinkerError.agentDirectoryCreationFailed(path: agentSkillsDir.path)
            }

            if (try? fileManager.attributesOfItem(atPath: symLinkDestination.path)) != nil {
                try fileManager.removeItem(at: symLinkDestination)
            }

            do {
                try fileManager.createSymbolicLink(at: symLinkDestination, withDestinationURL: skillSource)
            } catch {
                throw SkillSymLinkerError.symLinkCreationFailed(from: symLinkDestination.path, to: skillSource.path)
            }
        }
    }
}
