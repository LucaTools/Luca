//  PermissionManaging.swift

import Foundation

protocol PermissionManaging {
    func setExecutablePermission(for tool: EnrichedTool) throws
}
