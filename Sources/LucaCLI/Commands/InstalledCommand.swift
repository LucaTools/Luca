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
    
    @OptionGroup var commonFlags: CommonFlags

    @Flag(help: ArgumentHelp(
        "List installed skills instead of binary tools."
    ))
    var skills: Bool = false

    @Flag(help: "List globally-installed skills from ~/.luca/skills/.")
    var global: Bool = false

    func run() async throws {
        let noora = Noora(terminal: Terminal(signalBehavior: .none))
        let printer = Printer(noora: noora)
        let fileManager = FileManagerWrapper()

        if global && !skills {
            throw ValidationError("--global requires --skills. Use: luca installed --skills --global")
        }

        if skills {
            let lister = InstalledSkillsLister(fileManager: fileManager)
            let installedSkills = try lister.installedSkills(isGlobal: global)
            if installedSkills.isEmpty {
                printer.printFormatted("\(.info("No skills installed."))")
            } else {
                for name in installedSkills.keys.sorted() {
                    printer.printFormatted("\(.primary("\(name):"))")
                    for version in installedSkills[name] ?? [] {
                        printer.printFormatted("\(.raw("  - \(version)"))")
                    }
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
