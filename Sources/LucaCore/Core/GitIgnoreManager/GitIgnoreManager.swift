//  GitIgnoreManager.swift

import Foundation
import Noora

public struct GitIgnoreManager {
    
    private let fileManager: GitIgnoreFileManaging
    private let noora: Noorable
    
    public init(fileManager: GitIgnoreFileManaging, noora: Noorable) {
        self.fileManager = fileManager
        self.noora = noora
    }
    
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
                print(noora.format("\(.raw("🙈 Added \(entryToAdd) to .gitignore"))"))
            }
        } else {
            let content = entryToAdd + "\n"
            try fileManager.writeString(content, to: gitIgnoreFile)
            print(noora.format("\(.raw("🙈 Created .gitignore with \(entryToAdd)"))"))
        }
    }
}
