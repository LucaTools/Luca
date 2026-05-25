//  GitHookInstaller.swift

import Foundation
import LucaCore
import Noora

/// Installs a post-checkout Git hook into the current repository.
public struct GitHookInstaller {

    /// Identifier embedded in the hook script to recognise Luca-managed hooks.
    static let hookIdentifier = "LUCA POST-CHECKOUT GIT HOOK"

    private let fileManager: GitHookInstallerFileManaging
    private let printer: Printing
    private let noora: Noorable

    public init(fileManager: GitHookInstallerFileManaging, printer: Printing, noora: Noorable) {
        self.fileManager = fileManager
        self.printer = printer
        self.noora = noora
    }

    /// Copies the Luca post-checkout hook into `.git/hooks/`.
    ///
    /// - If no hook exists, installs the hook.
    /// - If a Luca-managed hook exists (detected by ``hookIdentifier``), replaces it.
    /// - If a non-Luca hook exists, skips to preserve user customisations.
    public func installPostCheckoutHook() throws {
        let currentDirectory = URL(fileURLWithPath: fileManager.currentDirectoryPath)
        let gitDirectory = currentDirectory.appending(component: ".git")

        // Skip if not a git repository
        guard fileManager.fileExists(atPath: gitDirectory.path) else {
            return
        }

        // In a git worktree, `.git` is a file (not a directory) pointing to the main repo.
        // Hooks live in the main repo; skip installation to avoid failing in a worktree context.
        guard (try? fileManager.attributesOfItem(atPath: gitDirectory.path)[.type] as? FileAttributeType) == .typeDirectory else {
            return
        }

        let sourceHookPath = fileManager.homeDirectoryForCurrentUser
            .appending(components: Constants.toolFolder, "post-checkout")

        // Warn and continue if source hook doesn't exist
        guard fileManager.fileExists(atPath: sourceHookPath.path) else {
            printer.printFormatted("\(.raw("⚠️ Post-checkout hook source not found at \(sourceHookPath.path)"))")
            return
        }

        let hooksDirectory = gitDirectory.appending(component: "hooks")
        let destinationHookPath = hooksDirectory.appending(component: "post-checkout")

        if !fileManager.fileExists(atPath: hooksDirectory.path) {
            let shouldCreate = noora.yesOrNoChoicePrompt(
                title: "Create missing hooks folder",
                question: "The .git/hooks directory does not exist. Would you like Luca to create it?",
                defaultAnswer: true,
                description: nil,
                collapseOnSelection: true
            )
            guard shouldCreate else { return }
            try fileManager.createDirectory(at: hooksDirectory, withIntermediateDirectories: true)
        }

        if fileManager.fileExists(atPath: destinationHookPath.path) {
            // Check if the existing hook is a Luca-managed hook
            let existingContent = try fileManager.readString(at: destinationHookPath)
            guard existingContent.contains(Self.hookIdentifier) else {
                // Non-Luca hook — preserve it
                return
            }

            // Luca hook — check if it needs updating
            let sourceContent = try fileManager.readString(at: sourceHookPath)
            guard existingContent != sourceContent else {
                // Already up to date
                return
            }

            // Replace outdated Luca hook
            try fileManager.removeItem(at: destinationHookPath)
            try fileManager.copyItem(at: sourceHookPath, to: destinationHookPath)
            try fileManager.setAttributes([.posixPermissions: 0o755], ofItemAtPath: destinationHookPath.path)
            printer.printFormatted("\(.info("🪝 Updated post-checkout hook"))")
        } else {
            // No hook exists — install
            try fileManager.copyItem(at: sourceHookPath, to: destinationHookPath)
            try fileManager.setAttributes([.posixPermissions: 0o755], ofItemAtPath: destinationHookPath.path)
            printer.printFormatted("\(.info("🪝 Installed post-checkout hook"))")
        }
    }
}
