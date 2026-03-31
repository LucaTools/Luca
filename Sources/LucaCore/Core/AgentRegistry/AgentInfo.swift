//  AgentInfo.swift

/// Metadata for a known AI coding agent.
///
/// `AgentInfo` holds the agent's canonical identifier and the paths where skills
/// are stored for that agent, both relative to the project root and in the user's
/// home directory for global installation.
public struct AgentInfo: Sendable, Equatable {
    /// The canonical identifier for the agent (e.g. `"claude-code"`).
    public let id: String
    /// Path relative to the project root where the agent reads its skill files (e.g. `".claude/skills"`).
    public let projectSkillsPath: String
    /// Absolute path in the user's home directory where the agent reads globally installed skill files (e.g. `"~/.claude/skills"`).
    public let globalSkillsPath: String
}
