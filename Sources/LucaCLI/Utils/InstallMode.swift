//  InstallMode.swift

/// Controls which components are installed during a `luca install` run.
public enum InstallMode {
    /// Install both tools and skills (default).
    case all
    /// Install only binary tools; skip skills.
    case toolsOnly
    /// Install only skills; skip binary tools.
    case skillsOnly
}
