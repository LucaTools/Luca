//  CleanCommand.swift

import Foundation
import ArgumentParser
import LucaCore

/// Removes all installed tool versions and active symlinks for the current directory.
struct CleanCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "clean",
        abstract: "Clean the folders containing the installed tools and the symlinks."
    )

    var fileManager: FileManager { FileManager.default }

    func run() async throws {
        let cleaner = Cleaner(fileManager: fileManager)
        try cleaner.clean()
    }
}
