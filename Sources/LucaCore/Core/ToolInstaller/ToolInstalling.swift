//  ToolInstalling.swift

import Foundation

/// Downloads, validates, and installs a single tool from its remote URL.
protocol ToolInstalling {
    /// Installs the given tool.
    ///
    /// - Parameter tool: The ``Tool`` to download, validate, and install.
    func install(tool: Tool) async throws
}
