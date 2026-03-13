//  SubprocessRunnerMock.swift

import Foundation
@testable import LucaCore

class SubprocessRunnerMock: SubprocessRunning, @unchecked Sendable {

    /// Exit codes returned in order per call. If exhausted, the last value is reused.
    var exitCodes: [Int32] = [0]
    var recordedArguments: [[String]] = []

    private var callCount = 0

    func run(executableURL: URL, arguments: [String]) throws -> Int32 {
        recordedArguments.append(arguments)
        let code = exitCodes.indices.contains(callCount) ? exitCodes[callCount] : exitCodes[exitCodes.count - 1]
        callCount += 1
        return code
    }
}
