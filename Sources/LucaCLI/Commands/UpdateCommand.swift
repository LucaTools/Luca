//  UpdateCommand.swift

import ArgumentParser
import Foundation
import LucaCore

/// Updates the `luca` binary to the latest available GitHub release.
struct UpdateCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "update",
        abstract: "Update luca to the latest available release."
    )

    mutating func run() async throws {
        let fileManager = FileManagerWrapper()
        let printer = Printer()
        let updater = SelfUpdater(fileManager: fileManager, printer: printer)
        try await updater.updateToLatest(currentVersion: version)
    }
}
