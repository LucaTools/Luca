//  SkillSymLinking.swift

/// Creates and manages symbolic links for installed skills.
protocol SkillSymLinking {
    /// Creates symbolic links for a skill in each agent's skills directory.
    ///
    /// - Parameters:
    ///   - skillName: The name of the skill to symlink.
    ///   - version: The installed version, used to resolve the versioned cache folder.
    ///   - agents: The agents for which to create symlinks.
    ///   - isGlobal: When `true`, links from `~/.luca/skills/` to each agent's global skills path.
    func setSymLink(skillName: String, version: String, agents: [AgentInfo], isGlobal: Bool) throws
}
