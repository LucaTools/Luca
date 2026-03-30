//  AgentRegistry.swift

/// Registry of all known AI coding agents and their project skill directory paths.
///
/// `AgentRegistry` provides a static catalogue of agents drawn from the Vercel Labs
/// agent-skills registry. Use it to look up project-relative skill paths or to
/// validate agent identifiers supplied by the user.
public struct AgentRegistry {

    // MARK: - All agents

    /// Complete list of known AI coding agents.
    public static let all: [AgentInfo] = [
        AgentInfo(id: "claude-code",          projectSkillsPath: ".claude/skills"),
        AgentInfo(id: "cursor",               projectSkillsPath: ".cursor/rules"),
        AgentInfo(id: "cline",                projectSkillsPath: ".cline/rules"),
        AgentInfo(id: "continue",             projectSkillsPath: ".continue/rules"),
        AgentInfo(id: "opencode",             projectSkillsPath: ".opencode/rules"),
        AgentInfo(id: "github-copilot",       projectSkillsPath: ".github/copilot-instructions"),
        AgentInfo(id: "aider",                projectSkillsPath: ".aider/skills"),
        AgentInfo(id: "zed",                  projectSkillsPath: ".zed/skills"),
        AgentInfo(id: "windsurf",             projectSkillsPath: ".windsurf/rules"),
        AgentInfo(id: "amp",                  projectSkillsPath: ".amp/skills"),
        AgentInfo(id: "codex",                projectSkillsPath: ".codex/skills"),
        AgentInfo(id: "bolt",                 projectSkillsPath: ".bolt/skills"),
        AgentInfo(id: "lovable",              projectSkillsPath: ".lovable/skills"),
        AgentInfo(id: "v0",                   projectSkillsPath: ".v0/skills"),
        AgentInfo(id: "replit",               projectSkillsPath: ".replit/skills"),
        AgentInfo(id: "devin",                projectSkillsPath: ".devin/skills"),
        AgentInfo(id: "openai-codex",         projectSkillsPath: ".openai-codex/skills"),
        AgentInfo(id: "gemini-cli",           projectSkillsPath: ".gemini/skills"),
        AgentInfo(id: "copilot-workspace",    projectSkillsPath: ".copilot-workspace/skills"),
        AgentInfo(id: "goose",                projectSkillsPath: ".goose/skills"),
        AgentInfo(id: "plandex",              projectSkillsPath: ".plandex/skills"),
        AgentInfo(id: "trae",                 projectSkillsPath: ".trae/skills"),
        AgentInfo(id: "roo-code",             projectSkillsPath: ".roo-code/skills"),
        AgentInfo(id: "kiro",                 projectSkillsPath: ".kiro/skills"),
        AgentInfo(id: "aide",                 projectSkillsPath: ".aide/skills"),
        AgentInfo(id: "claude-dev",           projectSkillsPath: ".claude-dev/skills"),
        AgentInfo(id: "continue-dev",         projectSkillsPath: ".continue-dev/skills"),
    ]

    // MARK: - Lookup

    /// Returns the `AgentInfo` entries matching the given identifiers.
    ///
    /// Unknown identifiers are silently ignored.
    ///
    /// - Parameter ids: The agent identifiers to look up.
    /// - Returns: An array of `AgentInfo` values for each recognised id, in the order they appear in `ids`.
    public static func agents(for ids: [String]) -> [AgentInfo] {
        let lookup = Dictionary(uniqueKeysWithValues: all.map { ($0.id, $0) })
        return ids.compactMap { lookup[$0] }
    }

    /// Returns a sorted list of all known agent identifiers.
    ///
    /// - Returns: Alphabetically sorted array of agent id strings.
    public static func allAgentIds() -> [String] {
        all.map(\.id).sorted()
    }
}
