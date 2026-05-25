//  SymLinking.swift

import Foundation
import LucaFoundation

/// Creates a symlink for an installed tool in the tools folder.
protocol SymLinking {
    /// Creates or replaces the symlink for `tool` in the project's `.luca/tools/` directory.
    /// - Parameter tool: The tool to link.
    /// - Returns: The URL of the created symlink.
    func setSymLink(for tool: Tool) throws -> URL
}
