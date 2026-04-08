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
        AgentInfo(id: "adal",           projectSkillsPath: ".adal/skills",          globalSkillsPath: "~/.adal/skills"),
        AgentInfo(id: "amp",            projectSkillsPath: ".agents/skills",        globalSkillsPath: "~/.config/agents/skills"),
        AgentInfo(id: "antigravity",    projectSkillsPath: ".agents/skills",        globalSkillsPath: "~/.gemini/antigravity/skills"),
        AgentInfo(id: "augment",        projectSkillsPath: ".augment/skills",       globalSkillsPath: "~/.augment/skills"),
        AgentInfo(id: "bob",            projectSkillsPath: ".bob/skills",           globalSkillsPath: "~/.bob/skills"),
        AgentInfo(id: "claude-code",    projectSkillsPath: ".claude/skills",        globalSkillsPath: "~/.claude/skills"),
        AgentInfo(id: "cline",          projectSkillsPath: ".agents/skills",        globalSkillsPath: "~/.agents/skills"),
        AgentInfo(id: "codebuddy",      projectSkillsPath: ".codebuddy/skills",     globalSkillsPath: "~/.codebuddy/skills"),
        AgentInfo(id: "codex",          projectSkillsPath: ".agents/skills",        globalSkillsPath: "~/.codex/skills"),
        AgentInfo(id: "command-code",   projectSkillsPath: ".commandcode/skills",   globalSkillsPath: "~/.commandcode/skills"),
        AgentInfo(id: "continue",       projectSkillsPath: ".continue/skills",      globalSkillsPath: "~/.continue/skills"),
        AgentInfo(id: "cortex",         projectSkillsPath: ".cortex/skills",        globalSkillsPath: "~/.snowflake/cortex/skills"),
        AgentInfo(id: "crush",          projectSkillsPath: ".crush/skills",         globalSkillsPath: "~/.config/crush/skills"),
        AgentInfo(id: "cursor",         projectSkillsPath: ".agents/skills",        globalSkillsPath: "~/.cursor/skills"),
        AgentInfo(id: "deepagents",     projectSkillsPath: ".agents/skills",        globalSkillsPath: "~/.deepagents/agent/skills"),
        AgentInfo(id: "droid",          projectSkillsPath: ".factory/skills",       globalSkillsPath: "~/.factory/skills"),
        AgentInfo(id: "firebender",     projectSkillsPath: ".agents/skills",        globalSkillsPath: "~/.firebender/skills"),
        AgentInfo(id: "gemini-cli",     projectSkillsPath: ".agents/skills",        globalSkillsPath: "~/.gemini/skills"),
        AgentInfo(id: "github-copilot", projectSkillsPath: ".agents/skills",        globalSkillsPath: "~/.copilot/skills"),
        AgentInfo(id: "goose",          projectSkillsPath: ".goose/skills",         globalSkillsPath: "~/.config/goose/skills"),
        AgentInfo(id: "iflow-cli",      projectSkillsPath: ".iflow/skills",         globalSkillsPath: "~/.iflow/skills"),
        AgentInfo(id: "junie",          projectSkillsPath: ".junie/skills",         globalSkillsPath: "~/.junie/skills"),
        AgentInfo(id: "kilo",           projectSkillsPath: ".kilocode/skills",      globalSkillsPath: "~/.kilocode/skills"),
        AgentInfo(id: "kimi-cli",       projectSkillsPath: ".agents/skills",        globalSkillsPath: "~/.config/agents/skills"),
        AgentInfo(id: "kiro-cli",       projectSkillsPath: ".kiro/skills",          globalSkillsPath: "~/.kiro/skills"),
        AgentInfo(id: "kode",           projectSkillsPath: ".kode/skills",          globalSkillsPath: "~/.kode/skills"),
        AgentInfo(id: "mcpjam",         projectSkillsPath: ".mcpjam/skills",        globalSkillsPath: "~/.mcpjam/skills"),
        AgentInfo(id: "mistral-vibe",   projectSkillsPath: ".vibe/skills",          globalSkillsPath: "~/.vibe/skills"),
        AgentInfo(id: "mux",            projectSkillsPath: ".mux/skills",           globalSkillsPath: "~/.mux/skills"),
        AgentInfo(id: "neovate",        projectSkillsPath: ".neovate/skills",       globalSkillsPath: "~/.neovate/skills"),
        AgentInfo(id: "openclaw",       projectSkillsPath: "skills",                globalSkillsPath: "~/.openclaw/skills"),
        AgentInfo(id: "opencode",       projectSkillsPath: ".agents/skills",        globalSkillsPath: "~/.config/opencode/skills"),
        AgentInfo(id: "openhands",      projectSkillsPath: ".openhands/skills",     globalSkillsPath: "~/.openhands/skills"),
        AgentInfo(id: "pi",             projectSkillsPath: ".pi/skills",            globalSkillsPath: "~/.pi/agent/skills"),
        AgentInfo(id: "pochi",          projectSkillsPath: ".pochi/skills",         globalSkillsPath: "~/.pochi/skills"),
        AgentInfo(id: "qoder",          projectSkillsPath: ".qoder/skills",         globalSkillsPath: "~/.qoder/skills"),
        AgentInfo(id: "qwen-code",      projectSkillsPath: ".qwen/skills",          globalSkillsPath: "~/.qwen/skills"),
        AgentInfo(id: "replit",         projectSkillsPath: ".agents/skills",        globalSkillsPath: "~/.config/agents/skills"),
        AgentInfo(id: "roo",            projectSkillsPath: ".roo/skills",           globalSkillsPath: "~/.roo/skills"),
        AgentInfo(id: "trae",           projectSkillsPath: ".trae/skills",          globalSkillsPath: "~/.trae/skills"),
        AgentInfo(id: "trae-cn",        projectSkillsPath: ".trae/skills",          globalSkillsPath: "~/.trae-cn/skills"),
        AgentInfo(id: "universal",      projectSkillsPath: ".agents/skills",        globalSkillsPath: "~/.config/agents/skills"),
        AgentInfo(id: "warp",           projectSkillsPath: ".agents/skills",        globalSkillsPath: "~/.agents/skills"),
        AgentInfo(id: "windsurf",       projectSkillsPath: ".windsurf/skills",      globalSkillsPath: "~/.codeium/windsurf/skills"),
        AgentInfo(id: "zencoder",       projectSkillsPath: ".zencoder/skills",      globalSkillsPath: "~/.zencoder/skills"),
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
