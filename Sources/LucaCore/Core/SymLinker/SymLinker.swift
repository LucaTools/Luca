//  SymLinker.swift

import Foundation

/// Creates and manages symbolic links for installed tools.
///
/// The `SymLinker` is responsible for creating symbolic links in the project's
/// `.luca/tools/` directory that point to the actual tool binaries stored
/// in `~/.luca/tools/`.
///
/// This allows projects to reference tools via a consistent path while
/// supporting multiple versions installed globally.
///
/// ## Topics
///
/// ### Creating Symlinks
/// - ``setSymLink(for:)``
struct SymLinker: SymLinking {
    
    enum SymLinkerError: Error, LocalizedError, Equatable {
        case missingBinaryFile(binaryName: String, expectedLocation: String)
        
        var errorDescription: String? {
            switch self {
            case .missingBinaryFile(let binaryName, let expectedLocation):
                return "Binary '\(binaryName)' could not be found at \(expectedLocation)."
            }
        }
    }
    
    private let fileManager: SymLinkFileManaging
    
    init(fileManager: SymLinkFileManaging) {
        self.fileManager = fileManager
    }
    
    // MARK: - Internal
    
    /// Creates a symbolic link for the specified tool.
    ///
    /// - Parameter tool: The tool to create a symlink for.
    /// - Returns: The URL of the created symlink.
    /// - Throws: ``SymLinkerError/missingBinaryFile(binaryName:expectedLocation:)``
    ///   if the binary file doesn't exist at the expected location.
    @discardableResult
    func setSymLink(for tool: Tool) throws -> URL {
        let symLinkFile = fileManager.symlinksFolder
            .appending(component: tool.expectedBinaryName)

        let destinationFile = fileManager.toolsFolder
            .appending(components: tool.name, tool.version)
            .appending(path: tool.effectiveBinaryPath)

        if !fileManager.fileExists(atPath: destinationFile.path) {
            throw SymLinkerError.missingBinaryFile(binaryName: tool.expectedBinaryName, expectedLocation: destinationFile.path)
        }
        if symLinkExists(atPath: symLinkFile.path) {
            try fileManager.removeItem(at: symLinkFile)
        }
        try fileManager.createDirectory(at: fileManager.symlinksFolder, withIntermediateDirectories: true)
        try fileManager.createSymbolicLink(at: symLinkFile, withDestinationURL: destinationFile)
        
        return symLinkFile
    }
    
    // MARK: - Private
    
    private func symLinkExists(atPath path: String) -> Bool {
        do {
            let attributes = try fileManager.attributesOfItem(atPath: path)
            if let fileType = attributes[.type] as? FileAttributeType {
                return fileType == .typeSymbolicLink
            }
            return false
        } catch {
            return false
        }
    }
}
