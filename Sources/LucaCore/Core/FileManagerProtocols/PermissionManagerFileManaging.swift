//  PermissionManagerFileManaging.swift

import Foundation

/// File system interface for ``PermissionManager``.
public protocol PermissionManagerFileManaging {
    var toolsFolder: URL { get }
    var activeFolder: URL { get }
    func fileExists(atPath: String) -> Bool
    func attributesOfItem(atPath path: String) throws -> [FileAttributeKey: Any]
    func setAttributes(_ attributes: [FileAttributeKey : Any], ofItemAtPath path: String) throws
}
