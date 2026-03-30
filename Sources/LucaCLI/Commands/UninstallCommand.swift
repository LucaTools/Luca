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
        "Tool or skill name to uninstall.",
        discussion: """
        For tools:
          luca uninstall SwiftLint
          luca uninstall SwiftLint@0.61.0
        For skills (with --only-skills --experimental):
          luca uninstall find-skills --only-skills --experimental
        """,
        valueName: "name[@version]"
    ))
    var tool: String

    @Flag(help: ArgumentHelp(
        "Uninstall a skill instead of a binary tool.",
        discussion: """
        Use with --experimental.
        Example:
          luca uninstall find-skills --only-skills --experimental
        """
    ))
    var onlySkills: Bool = false

    @Flag(help: ArgumentHelp(
        "Use native skills pipeline (experimental).",
        discussion: "Use with --only-skills."
    ))
    var experimental: Bool = false

    func run() async throws {
        let noora = Noora(terminal: Terminal(signalBehavior: .none))
        let printer = Printer(noora: noora)
        Header(printer: printer).printHeader()

        let fileManager = FileManagerWrapper(fileManager: .default)

        if onlySkills && experimental {
            let uninstaller = SkillUninstaller(fileManager: fileManager, printer: printer)
            try uninstaller.uninstall(skillName: tool, agents: AgentRegistry.all)
            return
        }

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
