//  Unlinker.swift

import Foundation

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
    private let printer: Printing
    
    public init(fileManager: FileManaging, printer: Printing) {
        self.fileManager = fileManager
        self.printer = printer
    }

    public func unlink(symlink: String) throws {
        let symlinkFile = fileManager.activeFolder.appending(component: symlink)
        if fileManager.fileExists(atPath: symlinkFile.path) {
            printer.printFormatted("\(.raw("👀 Removing symlink \(symlink)..."))")
            try fileManager.removeItem(at: symlinkFile)
            printer.printFormatted("\(.success("🙌 Symlink \(symlink) has been removed."))")
        } else {
            throw UninstallerError.symlinkNotFound(symlink: symlink)
        }
    }
}
