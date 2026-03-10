//  Unlinker.swift

import Foundation

/// Removes a symlink from the project's `.luca/tools/` directory.
public struct Unlinker {

    public enum UnlinkerError: Error, LocalizedError, Equatable {
        case symlinkNotFound(symlink: String)
        
        public var errorDescription: String? {
            switch self {
            case .symlinkNotFound(let symlink):
                return "Symlink '\(symlink)' not found."
            }
        }
    }

    private let fileManager: FileManaging
    private let printer: Printing
    
    public init(fileManager: FileManaging, printer: Printing) {
        self.fileManager = fileManager
        self.printer = printer
    }

    /// Removes the symlink named `symlink` from the tools folder.
    /// - Parameter symlink: The binary name of the symlink to remove.
    public func unlink(symlink: String) throws {
        let symlinkFile = fileManager.activeFolder.appending(component: symlink)
        if fileManager.fileExists(atPath: symlinkFile.path) {
            printer.printFormatted("\(.raw("👀 Removing symlink \(symlink)..."))")
            try fileManager.removeItem(at: symlinkFile)
            printer.printFormatted("\(.primary("🙌 Symlink \(symlink) has been removed."))")
            printer.printFormatted("")
        } else {
            throw UnlinkerError.symlinkNotFound(symlink: symlink)
        }
    }
}
