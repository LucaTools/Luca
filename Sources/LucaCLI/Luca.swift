//  LucaCLI.swift

import Foundation
import ArgumentParser

/// Entry point for the Luca command line interface.
@main
struct LucaCLI: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "luca",
        abstract: "A tool manager for macOS that helps you install and manage development tools.",
        version: version,
        subcommands: [
            InstallCommand.self,
            CleanCommand.self
        ]
    )
}
