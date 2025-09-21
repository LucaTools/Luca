//  UninstallCommand.swift

import ArgumentParser
import Foundation
import LucaCore
import Noora

/// Removes all installed tool versions and active symlinks for the current directory.
struct UninstallCommand: AsyncParsableCommand {
    
    static let configuration = CommandConfiguration(
        commandName: "uninstall",
        abstract: "Uninstall the installed tools and the symlinks in the current folder."
    )
    
    @Flag(name: .long, inversion: .prefixedNo, help: "Whether to delete all installed tools at $HOME/\(Constants.toolFolder)")
    var deleteInstalledTools: Bool = true
    
    @Flag(name: .long, inversion: .prefixedNo, help: "Whether to delete the symlinks in the current directory at pwd/\(Constants.toolFolder)")
    var deleteSymLinks: Bool = true

    private var noora: Noorable { Noora() }
    
    func run() async throws {
        Header(noora: noora).printHeader()

        let fileManager = FileManagerWrapper(fileManager: .default)
        let uninstaller = Uninstaller(fileManager: fileManager, noora: noora)
        
        try uninstaller.uninstall(
            installedTools: deleteInstalledTools,
            localSymLinks: deleteSymLinks
        )
    }
}
