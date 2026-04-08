//  Constants.swift

import Foundation

/// Names and values used across the Luca tool for folder / file conventions.
public struct Constants {
    /// Folder containing the symlinked binaries inside `toolFolder` in the current working directory.
    public static let symlinksFolder = "tools"
    /// Supported spec file extension.
    public static let ymlExtension = "yml"
    /// Default spec file name expected in the current working directory.
    public static let specFile = "Lucafile"
    /// Alternative spec file name for tool-only specs.
    public static let toolFile = "Toolfile"
    /// Alternative spec file name for skill-only specs.
    public static let skillFile = "Skillfile"
    /// All recognised spec file base names, in priority order.
    public static let specFiles = [specFile, toolFile, skillFile]
    /// Display name of the tool.
    public static let toolName = "Luca"
    /// Hidden root folder under home (and CWD for symlinks) where Luca keeps data.
    public static let toolFolder = ".luca"
    /// Subfolder under `toolFolder` where versioned tool installations live.
    public static let toolsFolder = "tools"
    /// Skills cache subfolder name, used for the project-local `.luca/skills/` directory.
    public static let skillsFolder = "skills"
}
