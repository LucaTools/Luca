//  SubprocessOutputRunnerMock.swift

import Foundation
@testable import LucaFoundation

final class SubprocessOutputRunnerMock: SubprocessOutputRunning, @unchecked Sendable {

    /// Results returned in order per call. If exhausted, the last value is reused.
    var results: [(exitCode: Int32, output: String)] = [(0, "")]
    var recordedExecutableURLs: [URL] = []
    var recordedArguments: [[String]] = []
    var recordedEnvironments: [[String: String]] = []

    private var callCount = 0

    func run(executableURL: URL, arguments: [String], environment: [String: String]) async throws -> (exitCode: Int32, output: String) {
        recordedExecutableURLs.append(executableURL)
        recordedArguments.append(arguments)
        recordedEnvironments.append(environment)
        let result = results.indices.contains(callCount) ? results[callCount] : results[results.count - 1]
        callCount += 1
        return result
    }
}
