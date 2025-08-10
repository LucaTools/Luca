//  Cleaner.swift

import Foundation

/// Removes previously installed tool versions and active symlinks.
final public class Cleaner {

    // Dependencies / environment roots.
    private let fileManager: FileManager
    private let homeDirectory: URL   // Typically the user home directory.
    private let currentWorkingDirectory: URL // Directory where symlinks live.

    public init(fileManager: FileManager) {
        self.fileManager = fileManager
        self.homeDirectory = fileManager.homeDirectoryForCurrentUser
        self.currentWorkingDirectory = URL(fileURLWithPath: fileManager.currentDirectoryPath)
    }

    /// Remove all versioned installs and active symlinks (idempotent).
    public func clean() throws {
        try cleanInstalledTools()
        try cleanSymLinks()
    }

    /// Delete the entire tools installation folder if present.
    private func cleanInstalledTools() throws {
        let toolsFolder = homeDirectory
            .appending(components: Constants.toolFolder)
            .appending(components: Constants.toolsFolder)

        if fileManager.fileExists(atPath: toolsFolder.path) {
            print("Removing all installed tools...")
            try fileManager.removeItem(atPath: toolsFolder.path)
            print("All tools have been removed.\n")
        } else {
            print("No tools to be removed.")
        }
    }

    /// Delete the folder containing active symlinks if present.
    private func cleanSymLinks() throws {
        let activeFolder = currentWorkingDirectory
            .appending(components: Constants.toolFolder)
            .appending(components: Constants.activeFolder)
        if fileManager.fileExists(atPath: activeFolder.path) {
            print("Removing all symlinks...")
            try fileManager.removeItem(atPath: activeFolder.path)
            print("All symlinks have been removed.\n")
        } else {
            print("No symlinks to be removed.")
        }
    }
}
