//  InstalledCommand.swift

import ArgumentParser
import Foundation
import LucaCore
import Noora

/// Lists all tools and their cached versions in the local Luca cache.
struct InstalledCommand: AsyncParsableCommand {
    
    static let configuration = CommandConfiguration(
        commandName: "installed",
        abstract: "List installed tools or skills and versions.",
        discussion: """
        Shows all tools in the local cache with their installed versions.
        Use 'luca linked' to see which versions are currently active.
        """
    )
    
    @Flag(help: ArgumentHelp(
        "List installed skills instead of binary tools."
    ))
    var skills: Bool = false

    func run() async throws {
        let noora = Noora(terminal: Terminal(signalBehavior: .none))
        let printer = Printer(noora: noora)
        let fileManager = FileManagerWrapper()

        if skills {
            let lister = InstalledSkillsLister(fileManager: fileManager)
            let skills = try lister.installedSkills()
            if skills.isEmpty {
                printer.printFormatted("\(.info("No skills installed."))")
            } else {
                for skill in skills {
                    printer.printFormatted("\(.primary(skill))")
                }
            }
            return
        }

        let lister = InstalledToolsLister(fileManager: fileManager)

        let installedTools = try lister.installedTools()
        
        if installedTools.isEmpty {
            printer.printFormatted("\(.info("No tools installed."))")
            return
        }
        
        let sortedTools = installedTools.keys.sorted()
        
        for tool in sortedTools {
            if let versions = installedTools[tool] {
                printer.printFormatted("\(.primary("\(tool):"))")
                for version in versions {
                    printer.printFormatted("\(.raw("  - \(version)"))")
                }
            }
        }
    }
}
