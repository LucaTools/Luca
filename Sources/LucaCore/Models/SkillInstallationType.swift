//  SkillInstallationType.swift

import Foundation

/// Specifies the source from which tools are resolved for installation.
public enum SkillInstallationType {
    /// Install all skills listed in a Lucafile at the given path.
    case spec(specPath: URL)
}
