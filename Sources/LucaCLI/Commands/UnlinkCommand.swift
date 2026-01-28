//  UnlinkCommand.swift

import ArgumentParser
import Foundation
import LucaCore

/// Removes a specific symlink from the active folder.
struct UnlinkCommand: AsyncParsableCommand {
    
    static let configuration = CommandConfiguration(
        commandName: "unlink",
        abstract: "Remove a symlink from the active folder.",
        discussion: """
        Removes the symlink without uninstalling the underlying tool.
        The tool remains available for re-linking to a different version.
        """
    )
    
    @Argument(help: ArgumentHelp(
        "Name of the symlink to remove.",
        discussion: """
        Example:
          luca unlink swiftlint
        """,
        valueName: "name"
    ))
    var symlink: String

    func run() async throws {
        let printer = Printer()
        Header(printer: printer).printHeader()

        let fileManager = FileManagerWrapper(fileManager: .default)
        let unlinker = Unlinker(fileManager: fileManager, printer: printer)
        
        try unlinker.unlink(symlink: symlink)
    }
}
