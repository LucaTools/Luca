//  LucaCommand.swift

import ArgumentParser
import Foundation

@main
struct LucaCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "luca",
        abstract: "A modern tool manager that helps you install and manage development tools.",
        version: version,
        subcommands: [
            InstallCommand.self,
            UninstallCommand.self,
            UnlinkCommand.self
        ]
    )
}
