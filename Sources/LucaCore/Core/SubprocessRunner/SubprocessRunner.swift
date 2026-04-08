//  SubprocessRunner.swift

import Foundation

/// Runs an external process using `Foundation.Process`.
///
/// `SubprocessRunner` wraps `Foundation.Process`, inheriting the parent's
/// stdout and stderr so output flows through to the terminal. The exit code
/// is returned directly to the caller.
struct SubprocessRunner: SubprocessRunning {

    /// Runs the executable at the given URL with the provided arguments and extra environment variables.
    ///
    /// - Parameters:
    ///   - executableURL: The URL of the executable to run.
    ///   - arguments: The command-line arguments to pass.
    ///   - environment: Additional environment variables merged on top of the inherited environment.
    ///     Pass an empty dictionary to inherit the environment unchanged.
    /// - Returns: The process termination status.
    func run(executableURL: URL, arguments: [String], environment: [String: String]) async throws -> Int32 {
        try await withCheckedThrowingContinuation { continuation in
            let process = Process()
            process.executableURL = executableURL
            process.arguments = arguments
            // Close stdin so any reads inside the subprocess return EOF immediately
            // rather than blocking on input that will never arrive.
            process.standardInput = FileHandle.nullDevice
            if !environment.isEmpty {
                var env = ProcessInfo.processInfo.environment
                env.merge(environment) { _, new in new }
                process.environment = env
            }
            process.terminationHandler = { p in
                continuation.resume(returning: p.terminationStatus)
            }
            do {
                try process.run()
            } catch {
                continuation.resume(throwing: error)
            }
        }
    }
}
