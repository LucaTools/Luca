//  PermissionManager.swift

import Foundation
import LucaCore

/// Applies executable permission bits to installed tool binaries.
struct PermissionManager: PermissionManaging {

    enum PermissionManagerError: Error, LocalizedError, Equatable {
        case missingFile(String)
        case unableToRetrievePosixPermissions(String)
        
        var errorDescription: String? {
            switch self {
            case .missingFile(let path):
                return "File at path '\(path)' is missing."
            case .unableToRetrievePosixPermissions(let path):
                return "Unable to retrieve POSIX permissions for file at '\(path)'."
            }
        }
    }

    private let fileManager: PermissionManagerFileManaging

    init(fileManager: PermissionManagerFileManaging) {
        self.fileManager = fileManager
    }
    
    /// Adds the execute bits (`0o111`) to the binary associated with `tool`.
    func setExecutablePermission(for tool: Tool) throws {
        let destinationFile = fileManager.toolsFolder
            .appending(components: tool.name, tool.version)
            .appending(path: tool.effectiveBinaryPath)
        
        guard fileManager.fileExists(atPath: destinationFile.path) else {
            throw PermissionManagerError.missingFile(destinationFile.path)
        }
        
        var attributes = try fileManager.attributesOfItem(atPath: destinationFile.path)
        if let currentPermissions = attributes[.posixPermissions] as? NSNumber {
            let newPermissions = currentPermissions.intValue | 0o111 // executable bits
            attributes[.posixPermissions] = NSNumber(value: newPermissions)
            try fileManager.setAttributes(attributes, ofItemAtPath: destinationFile.path)
        } else {
            throw PermissionManagerError.unableToRetrievePosixPermissions(destinationFile.path)
        }
    }
}
