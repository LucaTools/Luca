//  GitIgnoreManager.swift

import Foundation
import LucaFoundation

/// Ensures Luca's tools and skills folders stay untracked by git.
///
/// `.luca/tools/` and `.luca/skills/` get their own nested `.gitignore` rather than an entry in
/// the project's root `.gitignore`. Each agent's project skill directory (e.g. `.claude/skills/`)
/// still gets an entry appended to the root `.gitignore`, since those live outside `.luca/`.
public struct GitIgnoreManager {

    private let fileManager: GitIgnoreFileManaging
    private let printer: Printing

    /// Content of a nested `.gitignore` that ignores everything in its folder except itself.
    private static let nestedGitIgnoreContent = "*\n!.gitignore\n"

    public init(fileManager: GitIgnoreFileManaging, printer: Printing) {
        self.fileManager = fileManager
        self.printer = printer
    }

    /// Ensures the project's tools symlinks folder ignores its own contents.
    ///
    /// Writes a nested `.gitignore` inside `.luca/tools/` rather than editing the project's
    /// root `.gitignore`, so Luca never has to read or merge into a file it doesn't own.
    public func ensureGitIgnoreIncludesSymlinksFolder() throws {
        let currentDirectory = URL(fileURLWithPath: fileManager.currentDirectoryPath)
        let gitDirectory = currentDirectory.appending(component: ".git")

        guard fileManager.fileExists(atPath: gitDirectory.path) else {
            return
        }

        try writeNestedGitIgnore(in: fileManager.symlinksFolder, label: "\(Constants.toolFolder)/\(Constants.symlinksFolder)")
    }

    /// Ensures the project's skills cache folder ignores its own contents, and appends each
    /// agent's skill directory to the root `.gitignore`.
    ///
    /// - Parameter agents: The agents whose skill directories should be added to `.gitignore`.
    public func ensureGitIgnoreIncludesSkillFolders(agents: [AgentInfo]) throws {
        let currentDirectory = URL(fileURLWithPath: fileManager.currentDirectoryPath)
        let gitDirectory = currentDirectory.appending(component: ".git")

        guard fileManager.fileExists(atPath: gitDirectory.path) else {
            return
        }

        try writeNestedGitIgnore(in: fileManager.skillsCacheFolder, label: "\(Constants.toolFolder)/\(Constants.skillsFolder)")

        let entriesToAdd = agents.map(\.projectSkillsPath)
        guard !entriesToAdd.isEmpty else { return }

        let gitIgnoreFile = currentDirectory.appending(component: ".gitignore")

        if fileManager.fileExists(atPath: gitIgnoreFile.path) {
            var content = try fileManager.readString(at: gitIgnoreFile)
            var modified = false
            for entry in entriesToAdd {
                if !content.contains(entry) {
                    content = content.hasSuffix("\n") ? content + entry + "\n" : content + "\n" + entry + "\n"
                    modified = true
                    printer.printFormatted("\(.info("🙈 Added \(entry) to .gitignore"))")
                }
            }
            if modified {
                try fileManager.writeString(content, to: gitIgnoreFile)
            }
        } else {
            let content = entriesToAdd.joined(separator: "\n") + "\n"
            try fileManager.writeString(content, to: gitIgnoreFile)
            printer.printFormatted("\(.info("🙈 Created .gitignore with skills entries"))")
        }
    }

    // MARK: - Private

    /// Writes a `.gitignore` inside `folder` that ignores everything but itself, unless already present.
    private func writeNestedGitIgnore(in folder: URL, label: String) throws {
        try fileManager.createDirectory(at: folder, withIntermediateDirectories: true)

        let nestedGitIgnoreFile = folder.appending(component: ".gitignore")
        if fileManager.fileExists(atPath: nestedGitIgnoreFile.path) {
            let content = try fileManager.readString(at: nestedGitIgnoreFile)
            if content == Self.nestedGitIgnoreContent {
                return
            }
        }

        try fileManager.writeString(Self.nestedGitIgnoreContent, to: nestedGitIgnoreFile)
        printer.printFormatted("\(.info("🙈 Added .gitignore to \(label)"))")
    }
}
