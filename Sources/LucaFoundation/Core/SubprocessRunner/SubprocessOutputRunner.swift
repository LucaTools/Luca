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

            // Accumulate via a readability handler (rather than reading once at the end)
            // to avoid deadlocking if output exceeds the pipe's kernel buffer size.
            let accumulator = OutputAccumulator()
            stdoutPipe.fileHandleForReading.readabilityHandler = { handle in
                accumulator.append(handle.availableData)
            }

            process.terminationHandler = { finishedProcess in
                stdoutPipe.fileHandleForReading.readabilityHandler = nil
                let output = String(data: accumulator.value, encoding: .utf8) ?? ""
                continuation.resume(returning: (finishedProcess.terminationStatus, output))
            }

            do {
                try process.run()
            } catch {
                stdoutPipe.fileHandleForReading.readabilityHandler = nil
                continuation.resume(throwing: error)
            }
        }
    }
}

/// Thread-safe accumulator for data read incrementally off a pipe's readability handler,
/// which fires on a background queue concurrently with the continuation's closure.
private final class OutputAccumulator: @unchecked Sendable {
    private let lock = NSLock()
    private var data = Data()

    func append(_ chunk: Data) {
        lock.lock()
        data.append(chunk)
        lock.unlock()
    }

    var value: Data {
        lock.lock()
        defer { lock.unlock() }
        return data
    }
}
