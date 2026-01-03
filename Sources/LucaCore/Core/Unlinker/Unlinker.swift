//  Unlinker.swift

import Foundation
import Noora

public struct Unlinker {

    public enum UninstallerError: Error, LocalizedError, Equatable {
        case symlinkNotFound(symlink: String)
        
        public var errorDescription: String? {
            switch self {
            case .symlinkNotFound(let symlink):
                return "Symlink '\(symlink)' not found."
            }
        }
    }

    private let fileManager: FileManaging
    private let noora: Noorable
    
    public init(fileManager: FileManaging, noora: Noorable) {
        self.fileManager = fileManager
        self.noora = noora
    }

    public func unlink(symlink: String) throws {
        let symlinkFile = fileManager.activeFolder.appending(component: symlink)
        if fileManager.fileExists(atPath: symlinkFile.path) {
            print(noora.format("\(.raw("👀 Removing symlink \(symlink)..."))"))
            try fileManager.removeItem(at: symlinkFile)
            print(noora.format("\(.success("🙌 Symlink \(symlink) has been removed."))"))
        } else {
            throw UninstallerError.symlinkNotFound(symlink: symlink)
        }
    }
}
