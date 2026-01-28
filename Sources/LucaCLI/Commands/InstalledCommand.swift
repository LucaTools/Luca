//  InstalledCommand.swift

import ArgumentParser
import Foundation
import LucaCore

struct InstalledCommand: AsyncParsableCommand {
    
    static let configuration = CommandConfiguration(
        commandName: "installed",
        abstract: "List installed tools and versions.",
        discussion: """
        Shows all tools in the local cache with their installed versions.
        Use 'luca linked' to see which versions are currently active.
        """
    )
    
    func run() async throws {
        let printer = Printer()
        let fileManager = FileManagerWrapper()
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
