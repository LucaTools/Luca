//  Constants.swift

import Foundation

/// Names and values used across the Luca tool for folder / file conventions.
public struct Constants {
    /// Name of the folder containing the active (symlinked) binaries inside `.luca` in the current working directory.
    public static let activeFolder = "active"
    /// Supported spec file extension.
    public static let ymlExtension = "yml"
    /// Default spec file name expected in the current working directory.
    public static let specFile = "Lucafile"
    /// Display name of the tool.
    public static let toolName = "Luca"
    /// Hidden root folder under home (and CWD for symlinks) where Luca keeps data.
    public static let toolFolder = ".luca"
    /// Subfolder under `.luca` where versioned tool installations live.
    public static let toolsFolder = "tools"
}
