//  Cleaner.swift

import Foundation
import Noora

/// Removes previously installed tool versions and active symlinks.
final public class Cleaner {

    private let fileManager: FileManaging
    private let noora: Noorable
    
    public init(fileManager: FileManaging, noora: Noorable = Noora()) {
        self.fileManager = fileManager
        self.noora = noora
    }

    /// Remove all versioned installs
    public func cleanInstalledTools() throws {
        let toolsFolder = fileManager.toolsFolder
        if fileManager.fileExists(atPath: toolsFolder.path) {
            print(noora.format("\(.raw("Uninstalling all installed tools..."))"))
                try fileManager.removeItem(atPath: toolsFolder.path)
            print(noora.format("\(.success("All tools have been uninstallad."))"))
        } else {
            print(noora.format("\(.info("No tools installad. Nothing to uninstall."))"))
        }
    }

    /// Remove all active symlinks
    public func cleanSymLinks() throws {
        let activeFolder = fileManager.activeFolder
        if fileManager.fileExists(atPath: activeFolder.path) {
            print(noora.format("\(.raw("Deleting symlinks for current project..."))"))
            try fileManager.removeItem(atPath: activeFolder.path)
            print(noora.format("\(.success("All symlinks for current project have been deleted."))"))
        } else {
            print(noora.format("\(.info("No symlinks present. Nothing to delete."))"))
        }
    }
}
