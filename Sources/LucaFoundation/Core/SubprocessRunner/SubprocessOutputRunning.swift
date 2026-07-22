//  SubprocessOutputRunning.swift

import Foundation

/// Runs an external process and returns both its exit code and captured standard output.
///
/// Unlike ``SubprocessRunning``, which inherits stdout/stderr for interactive commands
/// (e.g. `git clone`, `unzip`), this protocol is for commands whose output must be
/// parsed programmatically (e.g. `git ls-remote`).
public protocol SubprocessOutputRunning: Sendable {
    /// Runs the executable at the given URL and captures its standard output.
    ///
    /// - Parameters:
    ///   - executableURL: The URL of the executable to run.
    ///   - arguments: The command-line arguments to pass.
    ///   - environment: Additional environment variables merged on top of the inherited environment.
    /// - Returns: The process termination status and the full contents of standard output.
    func run(executableURL: URL, arguments: [String], environment: [String: String]) async throws -> (exitCode: Int32, output: String)
}
