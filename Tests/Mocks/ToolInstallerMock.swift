//  ToolInstallerMock.swift

import Foundation
@testable import LucaFoundation
@testable import ManagerCore

class ToolInstallerMock: ToolInstalling, @unchecked Sendable {

    var installedTools: [Tool] = []
    var reinstalledTools: [Tool] = []
    var errorToThrow: Error?

    func install(tool: Tool) async throws {
        if let error = errorToThrow {
            throw error
        }
        installedTools.append(tool)
    }

    func reinstall(tool: Tool) throws {
        if let error = errorToThrow {
            throw error
        }
        reinstalledTools.append(tool)
    }
}
