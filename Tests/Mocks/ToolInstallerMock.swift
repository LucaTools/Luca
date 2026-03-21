//  ToolInstallerMock.swift

import Foundation
@testable import LucaCore

class ToolInstallerMock: ToolInstalling, @unchecked Sendable {

    var installedTools: [Tool] = []
    var errorToThrow: Error?

    func install(tool: Tool) async throws {
        if let error = errorToThrow {
            throw error
        }
        installedTools.append(tool)
    }
}
