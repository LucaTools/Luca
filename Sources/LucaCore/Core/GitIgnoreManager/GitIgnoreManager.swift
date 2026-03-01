//  GitIgnoreManager.swift

import Foundation

/// Ensures the project's `.gitignore` contains an entry for the `.luca/active/` folder.
public struct GitIgnoreManager {
    
    private let fileManager: GitIgnoreFileManaging
    private let printer: Printing
    
    public init(fileManager: GitIgnoreFileManaging, printer: Printing) {
        self.fileManager = fileManager
        self.printer = printer
    }
    
    /// Appends or creates a `.gitignore` entry for the active folder in the current project.
    public func ensureGitIgnoreIncludesActiveFolder() throws {
        let currentDirectory = URL(fileURLWithPath: fileManager.currentDirectoryPath)
        let gitDirectory = currentDirectory.appending(component: ".git")
        
        guard fileManager.fileExists(atPath: gitDirectory.path) else {
            return
        }
        
        let gitIgnoreFile = currentDirectory.appending(component: ".gitignore")
        let entryToAdd = "\(Constants.toolFolder)/\(Constants.activeFolder)"
        
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
}
