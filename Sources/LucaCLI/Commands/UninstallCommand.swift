//  UninstallCommand.swift

import ArgumentParser
import Foundation
import LucaCore
import Noora

/// Uninstall a specific tool version.
struct UninstallCommand: AsyncParsableCommand {
    
    static let configuration = CommandConfiguration(
        commandName: "uninstall",
        abstract: "Uninstall a specific tool version."
    )
    
    @Argument(help: "The tool to uninstall, optionally with version (e.g. SwiftLint@0.61.0)")
    var tool: String

    private var noora: Noorable { Noora() }
    
    func run() async throws {
        Header(noora: noora).printHeader()

        let fileManager = FileManagerWrapper(fileManager: .default)
        let uninstaller = Uninstaller(fileManager: fileManager, noora: noora)
        let versionLister = VersionLister(fileManager: fileManager)
        
        let components = tool.split(separator: "@")
        let toolName = String(components[0])
        
        if components.count > 1 {
            let version = String(components[1])
            try uninstaller.uninstall(tool: toolName, version: version)
        } else {
            let versions = try versionLister.listVersions(for: toolName)
            if versions.isEmpty {
                print(noora.format("\(.info("💁‍♂️ No versions found for \(toolName)."))"))
                return
            }
            
            let selectedVersion: String = noora.singleChoicePrompt(
                title: "Select version",
                question: "Which version of \(toolName) do you want to uninstall?",
                options: versions
            )
            
            try uninstaller.uninstall(tool: toolName, version: selectedVersion)
        }
    }
}
