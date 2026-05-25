//  ToolInstalling.swift

import Foundation
import LucaCore

/// Downloads, validates, installs, and reinstalls a single tool from its remote URL.
protocol ToolInstalling {
    /// Installs the given tool by downloading, validating, and linking it.
    ///
    /// - Parameter tool: The ``Tool`` to download, validate, and install.
    func install(tool: Tool) async throws

    /// Reinstalls an already-downloaded tool by setting permissions and recreating its symlink.
    ///
    /// - Parameter tool: The ``Tool`` to reinstall.
    func reinstall(tool: Tool) throws
}
