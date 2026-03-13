//  SubprocessRunner.swift

import Foundation

/// Runs an external process using `Foundation.Process`.
///
/// `SubprocessRunner` wraps `Foundation.Process`, routing stderr to a pipe
/// so callers can capture error output if needed. The exit code is returned
/// directly to the caller.
struct SubprocessRunner: SubprocessRunning {

    /// Runs the executable at the given URL with the provided arguments.
    ///
    /// - Parameters:
    ///   - executableURL: The URL of the executable to run.
    ///   - arguments: The command-line arguments to pass.
    /// - Returns: The process termination status.
    func run(executableURL: URL, arguments: [String]) throws -> Int32 {
        let process = Process()
        process.executableURL = executableURL
        process.arguments = arguments

        let stdoutPipe = Pipe()
        let stderrPipe = Pipe()
        process.standardOutput = stdoutPipe
        process.standardError = stderrPipe

        try process.run()
        process.waitUntilExit()

        return process.terminationStatus
    }
}
