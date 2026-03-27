//  UpdateCommand.swift

import ArgumentParser
import Foundation
import LucaCore
import Noora

/// Updates the `luca` binary to the latest available GitHub release.
struct UpdateCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "update",
        abstract: "Update luca to the latest available release."
    )

    mutating func run() async throws {
        let fileManager = FileManagerWrapper()
        let noora = Noora(terminal: Terminal(signalBehavior: .none))
        let printer = Printer(noora: noora)
        let updater = SelfUpdater(fileManager: fileManager, printer: printer)
        try await updater.updateToLatest(currentVersion: version)
    }
}
