//  SubprocessRunning.swift

import Foundation

/// Runs an external process and returns its exit code.
protocol SubprocessRunning: Sendable {
    /// Runs the executable at the given URL with the provided arguments.
    ///
    /// - Parameters:
    ///   - executableURL: The URL of the executable to run (e.g. `/usr/bin/env`).
    ///   - arguments: The command-line arguments to pass.
    /// - Returns: The process termination status.
    func run(executableURL: URL, arguments: [String]) async throws -> Int32
}
