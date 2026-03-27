//  EntryPoint.swift

import Foundation
import LucaCore
import Noora

/// The program entry point.
///
/// Performs a self-update check before handing off to `LucaCommand` for
/// argument parsing and command dispatch.
@main
struct LucaEntryPoint {
    static func main() async {
        let arguments = CommandLine.arguments.dropFirst()
        let isVersionRequest = arguments.count == 1 && arguments.contains("--version")

        if !isVersionRequest {
            let fileManager = FileManagerWrapper()
            let noora = Noora(terminal: Terminal(signalBehavior: .none))
            let printer = Printer(noora: noora)
            let updater = SelfUpdater(fileManager: fileManager, printer: printer)
            do {
                try await updater.updateIfNeeded(currentVersion: version)
            } catch {
                printer.printFormatted("\(.raw("⚠️  Auto-update failed: \(error.localizedDescription). Continuing with current version."))")
            }
        }

        await LucaCommand.main()
    }
}
