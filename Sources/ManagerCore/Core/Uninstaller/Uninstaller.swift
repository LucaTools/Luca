//  Uninstaller.swift

import Foundation
import LucaCore

/// Removes a specific version of a tool from the local cache.
public struct Uninstaller {

    public enum UninstallerError: Error, LocalizedError, Equatable {
        case versionNotFound(tool: String, version: String)
        
        public var errorDescription: String? {
            switch self {
            case .versionNotFound(let tool, let version):
                return "Version '\(version)' of tool '\(tool)' not found."
            }
        }
    }

    private let fileManager: FileManaging
    private let printer: Printing
    
    public init(fileManager: FileManaging, printer: Printing) {
        self.fileManager = fileManager
        self.printer = printer
    }

    /// Deletes the cached version directory for `tool` and removes the parent directory if empty.
    /// - Parameters:
    ///   - tool: The name of the tool to uninstall.
    ///   - version: The version string to remove.
    public func uninstall(tool: String, version: String) throws {
        let versionFolder = fileManager.toolsFolder
            .appending(component: tool)
            .appending(component: version)
        
        if fileManager.fileExists(atPath: versionFolder.path) {
            printer.printFormatted("\(.raw("👀 Uninstalling \(tool) \(version)..."))")
            try fileManager.removeItem(at: versionFolder)
            printer.printFormatted("\(.primary("🙌 \(tool) \(version) has been uninstalled."))")
            
            // Clean up tool folder if empty
            let toolFolder = fileManager.toolsFolder.appending(component: tool)
            if let contents = try? fileManager.contentsOfDirectory(at: toolFolder, includingPropertiesForKeys: nil, options: .skipsHiddenFiles), contents.isEmpty {
                try? fileManager.removeItem(at: toolFolder)
            }
        } else {
            throw UninstallerError.versionNotFound(tool: tool, version: version)
        }
    }
}
