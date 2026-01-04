//  UnlinkCommand.swift

import ArgumentParser
import Foundation
import LucaCore

/// Removes a specific symlink from the active folder.
struct UnlinkCommand: AsyncParsableCommand {
    
    static let configuration = CommandConfiguration(
        commandName: "unlink",
        abstract: "Removes a specific symlink from the active folder."
    )
    
    @Argument(help: "The name of the symlink to remove (e.g. swiftlint)")
    var symlink: String

    func run() async throws {
        let printer = Printer()
        Header(printer: printer).printHeader()

        let fileManager = FileManagerWrapper(fileManager: .default)
        let unlinker = Unlinker(fileManager: fileManager, printer: printer)
        
        try unlinker.unlink(symlink: symlink)
    }
}
