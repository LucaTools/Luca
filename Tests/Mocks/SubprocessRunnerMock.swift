//  SubprocessRunnerMock.swift

import Foundation
@testable import LucaCore

class SubprocessRunnerMock: SubprocessRunning, @unchecked Sendable {

    /// Exit codes returned in order per call. If exhausted, the last value is reused.
    var exitCodes: [Int32] = [0]
    var recordedArguments: [[String]] = []
    var recordedEnvironments: [[String: String]] = []
    var recordedWorkingDirectories: [URL?] = []
    var recordedInheritStdin: [Bool] = []

    private var callCount = 0

    func run(executableURL: URL, arguments: [String], environment: [String: String], workingDirectory: URL?, inheritStdin: Bool) async throws -> Int32 {
        recordedArguments.append(arguments)
        recordedEnvironments.append(environment)
        recordedWorkingDirectories.append(workingDirectory)
        recordedInheritStdin.append(inheritStdin)
        let code = exitCodes.indices.contains(callCount) ? exitCodes[callCount] : exitCodes[exitCodes.count - 1]
        callCount += 1
        return code
    }
}
