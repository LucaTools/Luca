//  LinkedCommand.swift

import ArgumentParser
import Foundation
import LucaCore
import Noora

struct LinkedCommand: AsyncParsableCommand {
    
    static let configuration = CommandConfiguration(
        commandName: "linked",
        abstract: "List tools linked in the current project."
    )
    
    private var noora: Noorable { Noora() }
    
    func run() async throws {
        let fileManager = FileManagerWrapper()
        let lister = LinkedToolsLister(fileManager: fileManager)
        
        let linkedTools = try lister.linkedTools()
        
        if linkedTools.isEmpty {
            print(noora.format("\(.info("No tools linked in the current project."))"))
            return
        }
        
        for tool in linkedTools.sorted(by: { $0.name < $1.name }) {
            print(noora.format("\(.primary("\(tool.name):"))"))
            print(noora.format("\(.raw("  version: \(tool.version)"))"))
            print(noora.format("\(.raw("  binary: \(tool.binaryName)"))"))
            print(noora.format("\(.raw("  location: \(tool.path)"))"))
        }
    }
}
