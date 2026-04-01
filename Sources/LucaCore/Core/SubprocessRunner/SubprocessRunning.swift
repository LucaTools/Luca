//  SubprocessRunning.swift

import Foundation

/// Runs an external process and returns its exit code.
protocol SubprocessRunning: Sendable {
    /// Runs the executable at the given URL with the provided arguments and extra environment variables.
    ///
    /// - Parameters:
    ///   - executableURL: The URL of the executable to run (e.g. `/usr/bin/env`).
    ///   - arguments: The command-line arguments to pass.
    ///   - environment: Additional environment variables merged on top of the inherited environment.
    /// - Returns: The process termination status.
    func run(executableURL: URL, arguments: [String], environment: [String: String]) async throws -> Int32
}

extension SubprocessRunning {
    /// Convenience overload that runs with no extra environment variables.
    func run(executableURL: URL, arguments: [String]) async throws -> Int32 {
        try await run(executableURL: executableURL, arguments: arguments, environment: [:])
    }
}
