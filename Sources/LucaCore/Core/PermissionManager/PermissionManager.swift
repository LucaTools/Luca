//  PermissionManager.swift

import Foundation

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
    
    func setExecutablePermission(for tool: EnrichedTool) throws {
        let destinationFile = fileManager.toolsFolder
            .appending(components: tool.name, tool.version)
            .appending(components: tool.binaryPath)
        
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
