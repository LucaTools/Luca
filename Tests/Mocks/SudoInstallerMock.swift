//  SudoInstallerMock.swift

import Foundation
@testable import LucaFoundation
@testable import ManagerCore

class SudoInstallerMock: SudoInstalling, @unchecked Sendable {

    var exitCode: Int32 = 0
    private(set) var calls: [(source: URL, destination: URL)] = []

    func install(from source: URL, to destination: URL) async throws -> Int32 {
        calls.append((source: source, destination: destination))
        return exitCode
    }
}
