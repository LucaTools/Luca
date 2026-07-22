//  SubprocessOutputRunner.swift

import Foundation

/// Runs an external process using `Foundation.Process`, capturing standard output.
///
/// Standard input is closed (`/dev/null`) so a subprocess that unexpectedly waits for
/// input returns immediately instead of hanging. Standard error is discarded.
public struct SubprocessOutputRunner: SubprocessOutputRunning {

    public init() {}

    public func run(executableURL: URL, arguments: [String], environment: [String: String]) async throws -> (exitCode: Int32, output: String) {
        try await withCheckedThrowingContinuation { continuation in
            DispatchQueue.global(qos: .utility).async {
                let process = Process()
                process.executableURL = executableURL
                process.arguments = arguments
                process.standardInput = FileHandle.nullDevice
                process.standardError = FileHandle.nullDevice

                if !environment.isEmpty {
                    var env = ProcessInfo.processInfo.environment
                    env.merge(environment) { _, new in new }
                    process.environment = env
                }

                let stdoutPipe = Pipe()
                process.standardOutput = stdoutPipe

                do {
                    try process.run()
                } catch {
                    continuation.resume(throwing: error)
                    return
                }

                // `readDataToEndOfFile()` drains the pipe continuously as the child writes to it,
                // so — unlike a single read after the process exits — it can never deadlock on a
                // full kernel pipe buffer. It returns once the write end closes, which happens
                // when the child exits, so `waitUntilExit()` below only reaps the exit status.
                let data = stdoutPipe.fileHandleForReading.readDataToEndOfFile()
                process.waitUntilExit()

                let output = String(data: data, encoding: .utf8) ?? ""
                continuation.resume(returning: (process.terminationStatus, output))
            }
        }
    }
}
