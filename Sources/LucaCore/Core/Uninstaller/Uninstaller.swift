//  Uninstaller.swift

import Foundation
import Noora

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
    private let noora: Noorable
    
    public init(fileManager: FileManaging, noora: Noorable = Noora()) {
        self.fileManager = fileManager
        self.noora = noora
    }

    public func uninstall(tool: String, version: String) throws {
        let versionFolder = fileManager.toolsFolder
            .appending(component: tool)
            .appending(component: version)
        
        if fileManager.fileExists(atPath: versionFolder.path) {
            print(noora.format("\(.raw("👀 Uninstalling \(tool) \(version)..."))"))
            try fileManager.removeItem(at: versionFolder)
            print(noora.format("\(.success("🙌 \(tool) \(version) has been uninstalled."))"))
            
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
