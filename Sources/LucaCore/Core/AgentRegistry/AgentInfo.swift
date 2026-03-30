//  AgentInfo.swift

/// Metadata for a known AI coding agent.
///
/// `AgentInfo` holds the agent's canonical identifier and the project-relative
/// path where skills (rule files) are stored for that agent.
public struct AgentInfo: Sendable, Equatable {
    /// The canonical identifier for the agent (e.g. `"claude-code"`).
    public let id: String
    /// Path relative to the project root where the agent reads its skill files (e.g. `".claude/skills"`).
    public let projectSkillsPath: String
}
