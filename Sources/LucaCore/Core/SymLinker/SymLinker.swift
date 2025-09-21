//  SymLinker.swift

import Foundation

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
    
    @discardableResult
    func setSymLink(for tool: EnrichedTool) throws -> URL {
        let symLinkFile = fileManager.activeFolder
            .appending(component: tool.binaryName)

        let destinationFile = fileManager.toolsFolder
            .appending(components: tool.name, tool.version)
            .appending(components: tool.binaryPath)

        if !fileManager.fileExists(atPath: destinationFile.path) {
            throw SymLinkerError.missingBinaryFile(binaryName: tool.binaryName, expectedLocation: destinationFile.path)
        }
        if symLinkExists(atPath: symLinkFile.path) {
            try fileManager.removeItem(at: symLinkFile)
        }
        try fileManager.createDirectory(at: fileManager.activeFolder, withIntermediateDirectories: true)
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
