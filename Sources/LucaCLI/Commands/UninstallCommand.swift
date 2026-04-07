//  UninstallCommand.swift

import ArgumentParser
import Foundation
import LucaCore
import Noora

/// Uninstall a specific tool or skill.
struct UninstallCommand: AsyncParsableCommand {

    static let configuration = CommandConfiguration(
        commandName: "uninstall",
        abstract: "Uninstall a specific tool or skill.",
        discussion: """
        Removes an installed tool version or skill from the local cache.
        For tools, if no version is specified, prompts for selection interactively.
        If no tool is found with the given name, attempts to uninstall a skill with that name.
        """
    )

    @Argument(help: ArgumentHelp(
        "Tool or skill name to uninstall.",
        discussion: """
        Tool examples:
          luca uninstall SwiftLint
          luca uninstall SwiftLint@0.61.0

        Skill examples:
          luca uninstall find-skills
        """,
        valueName: "name[@version]"
    ))
    var tool: String

    func run() async throws {
        let noora = Noora(terminal: Terminal(signalBehavior: .none))
        let printer = Printer(noora: noora)
        Header(printer: printer).printHeader()

        let fileManager = FileManagerWrapper(fileManager: .default)
        let uninstaller = Uninstaller(fileManager: fileManager, printer: printer)
        let versionLister = VersionLister(fileManager: fileManager)

        let components = tool.split(separator: "@")
        let toolName = String(components[0])

        if components.count > 1 {
            // Explicit version — must be a tool.
            let version = String(components[1])
            try uninstaller.uninstall(tool: toolName, version: version)
            return
        }

        // No version specified: try as a tool first, fall back to skill.
        do {
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
        } catch VersionLister.VersionListerError.toolNotFound {
            // No tool found — attempt skill uninstall.
            let skillUninstaller = SkillUninstaller(fileManager: fileManager, printer: printer)
            do {
                try skillUninstaller.uninstall(skillName: toolName, agents: AgentRegistry.all)
            } catch SkillUninstaller.SkillUninstallerError.skillNotFound {
                printer.printFormatted("\(.info("No tool or skill named '\(toolName)' was found."))")
            }
        }
    }
}
