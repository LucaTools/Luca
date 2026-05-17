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
    ///   - workingDirectory: The working directory for the process. When `nil`, the process inherits the current directory.
    ///   - inheritStdin: When `true`, stdin is inherited from the parent process. When `false`, stdin is set to `/dev/null`.
    /// - Returns: The process termination status.
    func run(executableURL: URL, arguments: [String], environment: [String: String], workingDirectory: URL?, inheritStdin: Bool) async throws -> Int32
}

extension SubprocessRunning {
    /// Convenience overload using no extra environment, current working directory, and closed stdin.
    func run(executableURL: URL, arguments: [String]) async throws -> Int32 {
        try await run(executableURL: executableURL, arguments: arguments, environment: [:], workingDirectory: nil, inheritStdin: false)
    }

    /// Convenience overload using current working directory and closed stdin.
    func run(executableURL: URL, arguments: [String], environment: [String: String]) async throws -> Int32 {
        try await run(executableURL: executableURL, arguments: arguments, environment: environment, workingDirectory: nil, inheritStdin: false)
    }
}
