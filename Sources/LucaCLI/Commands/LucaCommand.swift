//  LucaCommand.swift

import ArgumentParser
import Foundation

/// The root command for the `luca` CLI tool.
struct LucaCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "luca",
        abstract: "A modern tool manager that helps you install and manage development tools.",
        version: version,
        groupedSubcommands: [
            CommandGroup(name: "Installation", subcommands: [
                InstallCommand.self,
                UninstallCommand.self
            ]),
            CommandGroup(name: "Linking", subcommands: [
                LinkedCommand.self,
                UnlinkCommand.self
            ]),
            CommandGroup(name: "Listing", subcommands: [
                InstalledCommand.self
            ]),
            CommandGroup(name: "Validation", subcommands: [
                CalculateChecksumCommand.self
            ])
        ],
        defaultSubcommand: InstallCommand.self
    )
}
