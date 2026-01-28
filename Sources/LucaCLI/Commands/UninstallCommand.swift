//  UninstallCommand.swift

import ArgumentParser
import Foundation
import LucaCore
import Noora

/// Uninstall a specific tool version.
struct UninstallCommand: AsyncParsableCommand {
    
    static let configuration = CommandConfiguration(
        commandName: "uninstall",
        abstract: "Uninstall a specific tool version.",
        discussion: """
        Removes an installed tool version from the local cache.
        If no version is specified, prompts for selection interactively.
        """
    )
    
    @Argument(help: ArgumentHelp(
        "Tool to uninstall, optionally with version.",
        discussion: """
        Examples:
          luca uninstall SwiftLint
          luca uninstall SwiftLint@0.61.0
        """,
        valueName: "tool[@version]"
    ))
    var tool: String

    func run() async throws {
        let printer = Printer()
        let noora = Noora()
        Header(printer: printer).printHeader()

        let fileManager = FileManagerWrapper(fileManager: .default)
        let uninstaller = Uninstaller(fileManager: fileManager, printer: printer)
        let versionLister = VersionLister(fileManager: fileManager)
        
        let components = tool.split(separator: "@")
        let toolName = String(components[0])
        
        if components.count > 1 {
            let version = String(components[1])
            try uninstaller.uninstall(tool: toolName, version: version)
        } else {
            let versions = try versionLister.versions(for: toolName)
            if versions.isEmpty {
                printer.printFormatted("\(.info("💁‍♂️ No versions found for \(toolName)."))")
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
