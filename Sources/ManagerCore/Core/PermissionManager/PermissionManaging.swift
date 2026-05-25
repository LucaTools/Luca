//  PermissionManaging.swift

import Foundation
import LucaCore

/// Sets executable permissions on installed tool binaries.
protocol PermissionManaging {
    /// Adds execute permission bits to the binary of the given tool.
    /// - Parameter tool: The tool whose binary needs executable permissions.
    func setExecutablePermission(for tool: Tool) throws
}
