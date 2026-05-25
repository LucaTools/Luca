//  AgentsCommand.swift

import ArgumentParser
import Foundation
import LucaCore
import ManagerCore
import Noora

/// Lists all known agent identifiers that can be used with the `--agent` flag during skill installation.
struct AgentsCommand: AsyncParsableCommand {

    static let configuration = CommandConfiguration(
        commandName: "agents",
        abstract: "List available agent identifiers for skill installation.",
        discussion: """
        Shows all known AI coding agents whose skill directories Luca can target.
        Use these identifiers with the --agent flag when installing skills.

        Example:
          luca install AvdLee/Swift-Concurrency-Agent-Skill --agent claude-code --agent cursor
        """
    )

    @OptionGroup var commonFlags: CommonFlags

    func run() async throws {
        let noora = Noora(terminal: Terminal(signalBehavior: .none))
        let printer = Printer(noora: noora)

        let agents = AgentRegistry.all.sorted { $0.id < $1.id }

        let idHeader = "Id"
        let pathHeader = "Project Skills Path"
        let maxIdWidth = max(idHeader.count, agents.map(\.id.count).max() ?? 0)

        printer.printFormatted("\(.primary(idHeader.padding(toLength: maxIdWidth, withPad: " ", startingAt: 0)))\(.raw("  \(pathHeader)"))")
        let separator = String(repeating: "─", count: maxIdWidth) + "  " + String(repeating: "─", count: pathHeader.count)
        printer.printFormatted("\(.raw(separator))")

        for agent in agents {
            let paddedId = agent.id.padding(toLength: maxIdWidth, withPad: " ", startingAt: 0)
            printer.printFormatted("\(.primary(paddedId))\(.raw("  \(agent.projectSkillsPath)"))")
        }
    }
}
