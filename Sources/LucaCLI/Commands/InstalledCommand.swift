//  InstalledCommand.swift

import ArgumentParser
import Foundation
import LucaCore
import Noora

struct InstalledCommand: AsyncParsableCommand {
    
    static let configuration = CommandConfiguration(
        commandName: "installed",
        abstract: "List installed tools and versions."
    )
    
    private var noora: Noorable { Noora() }
    
    func run() async throws {
        let fileManager = FileManagerWrapper()
        let lister = InstalledToolsLister(fileManager: fileManager)
        
        let installedTools = try lister.installedTools()
        
        if installedTools.isEmpty {
            print(noora.format("\(.info("No tools installed."))"))
            return
        }
        
        let sortedTools = installedTools.keys.sorted()
        
        for tool in sortedTools {
            if let versions = installedTools[tool] {
                print(noora.format("\(.raw("\(tool):"))"))
                for version in versions {
                    print(noora.format("\(.raw("  - \(version)"))"))
                }
            }
        }
    }
}
