//  GitIgnoreManager.swift

import Foundation

/// Ensures the project's `.gitignore` contains entries for the tools and skills folders.
public struct GitIgnoreManager {

    private let fileManager: GitIgnoreFileManaging
    private let printer: Printing

    public init(fileManager: GitIgnoreFileManaging, printer: Printing) {
        self.fileManager = fileManager
        self.printer = printer
    }

    /// Appends or creates a `.gitignore` entry for the tools folder in the current project.
    public func ensureGitIgnoreIncludesSymlinksFolder() throws {
        let currentDirectory = URL(fileURLWithPath: fileManager.currentDirectoryPath)
        let gitDirectory = currentDirectory.appending(component: ".git")

        guard fileManager.fileExists(atPath: gitDirectory.path) else {
            return
        }

        let gitIgnoreFile = currentDirectory.appending(component: ".gitignore")
        let entryToAdd = "\(Constants.toolFolder)/\(Constants.symlinksFolder)"

        if fileManager.fileExists(atPath: gitIgnoreFile.path) {
            let content = try fileManager.readString(at: gitIgnoreFile)
            if !content.contains(entryToAdd) {
                let newContent = content.hasSuffix("\n") ? content + entryToAdd + "\n" : content + "\n" + entryToAdd + "\n"
                try fileManager.writeString(newContent, to: gitIgnoreFile)
                printer.printFormatted("\(.info("🙈 Added \(entryToAdd) to .gitignore"))")
            }
        } else {
            let content = entryToAdd + "\n"
            try fileManager.writeString(content, to: gitIgnoreFile)
            printer.printFormatted("\(.info("🙈 Created .gitignore with \(entryToAdd)"))")
        }
    }

    /// Appends or creates `.gitignore` entries for the skills cache folder and each agent's skill directory.
    ///
    /// - Parameter agents: The agents whose skill directories should be added to `.gitignore`.
    public func ensureGitIgnoreIncludesSkillFolders(agents: [AgentInfo]) throws {
        let currentDirectory = URL(fileURLWithPath: fileManager.currentDirectoryPath)
        let gitDirectory = currentDirectory.appending(component: ".git")

        guard fileManager.fileExists(atPath: gitDirectory.path) else {
            return
        }

        let gitIgnoreFile = currentDirectory.appending(component: ".gitignore")
        var entriesToAdd = ["\(Constants.toolFolder)/\(Constants.skillsFolder)"]
        entriesToAdd += agents.map(\.projectSkillsPath)

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
}
