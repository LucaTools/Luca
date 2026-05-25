//  UpdateCommand.swift

import ArgumentParser
import Foundation
import LucaCore
import ManagerCore
import Noora

/// Updates the `luca` binary to the latest available GitHub release.
struct UpdateCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "update",
        abstract: "Update luca to the latest available release."
    )

    @Flag(help: ArgumentHelp(
        "Only refresh the helper scripts without updating the CLI binary.",
        discussion: """
        Downloads the latest post-checkout and shell_hook.sh scripts \
        to ~/.luca/ without checking for a new Luca release.
        """
    ))
    var onlyScripts: Bool = false

    mutating func run() async throws {
        let fileManager = FileManagerWrapper()
        let noora = Noora(terminal: Terminal(signalBehavior: .none))
        let printer = Printer(noora: noora)
        let updater = SelfUpdater(fileManager: fileManager, printer: printer)

        if onlyScripts {
            await updater.refreshScripts()
        } else {
            try await updater.updateToLatest(currentVersion: version)
        }
    }
}
