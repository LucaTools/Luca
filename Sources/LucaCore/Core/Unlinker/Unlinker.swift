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
    ///
    /// When the symlink exists but its target has been removed (e.g. the tool was
    /// previously uninstalled), the dangling symlink is still removed and the user
    /// is informed that the tool is not installed. If no symlink exists at all, the
    /// command prints an informational message instead of throwing.
    /// - Parameter symlink: The binary name of the symlink to remove.
    public func unlink(symlink: String) throws {
        let symlinkFile = fileManager.symlinksFolder.appending(component: symlink)
        let symlinkPath = symlinkFile.path

        // attributesOfItem does not follow symlinks, so it detects dangling symlinks
        // that fileExists would miss.
        let symlinkExists = (try? fileManager.attributesOfItem(atPath: symlinkPath)) != nil

        guard symlinkExists else {
            throw UnlinkerError.symlinkNotFound(symlink: symlink)
        }

        // fileExists follows symlinks — false means the target (installed tool) is gone.
        let toolInstalled = fileManager.fileExists(atPath: symlinkPath)

        printer.printFormatted("\(.raw("👀 Removing symlink \(symlink)..."))")
        try fileManager.removeItem(at: symlinkFile)
        printer.printFormatted("\(.primary("🙌 Symlink \(symlink) has been removed."))")
        if !toolInstalled {
            printer.printFormatted("\(.info("💁‍♂️ Tool \(symlink) is not installed."))")
        }
        printer.printFormatted("")
    }
}
