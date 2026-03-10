//  LinkedCommand.swift

import ArgumentParser
import Foundation
import LucaCore

/// Lists tools currently symlinked in the tools folder of the current project.
struct LinkedCommand: AsyncParsableCommand {
    
    static let configuration = CommandConfiguration(
        commandName: "linked",
        abstract: "List tools linked in the current project.",
        discussion: """
        Shows all symlinks in the tools folder with their versions and paths.
        Use 'luca installed' to see all available tool versions.
        """
    )
    
    func run() async throws {
        let printer = Printer()
        let fileManager = FileManagerWrapper()
        let lister = LinkedToolsLister(fileManager: fileManager)
        
        let linkedTools = try lister.linkedTools()
        
        if linkedTools.isEmpty {
            printer.printFormatted("\(.info("No tools linked in the current project."))")
            return
        }
        
        for tool in linkedTools.sorted(by: { $0.name < $1.name }) {
            printer.printFormatted("\(.primary("\(tool.name):"))")
            printer.printFormatted("\(.raw("  version: \(tool.version)"))")
            printer.printFormatted("\(.raw("  binary: \(tool.binaryName)"))")
            printer.printFormatted("\(.raw("  location: \(tool.path)"))")
        }
    }
}
