//  PipelineRunner.swift

import Foundation
import Noora

/// Executes a ``Pipeline`` task by task, printing headers and streaming subprocess output.
///
/// Each task runs inside `/bin/bash -c "set -eo pipefail && <command>"`.
/// Environment variables are merged in order: inherited process env ← pipeline-level env ← task-level env.
/// Working directory is resolved as: task-level → pipeline-level → invocation directory.
public struct PipelineRunner: PipelineRunning {

    public enum PipelineRunnerError: Error, LocalizedError, Equatable {
        case taskFailed(taskName: String, exitCode: Int32)

        public var errorDescription: String? {
            switch self {
            case .taskFailed(let taskName, let exitCode):
                return "Task '\(taskName)' failed with exit code \(exitCode)."
            }
        }
    }

    private let subprocessRunner: SubprocessRunning
    private let printer: Printing

    /// Creates a runner using the default subprocess executor.
    public init(printer: Printing) {
        self.subprocessRunner = SubprocessRunner()
        self.printer = printer
    }

    /// Creates a runner with a custom subprocess executor (used in tests).
    init(subprocessRunner: SubprocessRunning, printer: Printing) {
        self.subprocessRunner = subprocessRunner
        self.printer = printer
    }

    // MARK: - PipelineRunning

    public func run(_ pipeline: Pipeline, currentDirectoryURL: URL) async throws {
        let start = Date()
        let tasks = pipeline.tasks

        for (index, task) in tasks.enumerated() {
            printTaskHeader(index: index + 1, total: tasks.count, name: task.name)

            let env = mergedEnvironment(pipelineEnv: pipeline.env, taskEnv: task.env)
            let workingDirectory = resolveWorkingDirectory(task: task, pipeline: pipeline, invocationDirectory: currentDirectoryURL)

            let exitCode = try await subprocessRunner.run(
                executableURL: URL(fileURLWithPath: "/bin/bash"),
                arguments: ["-c", "set -eo pipefail && \(task.command)"],
                environment: env,
                workingDirectory: workingDirectory,
                inheritStdin: true
            )

            if exitCode != 0 {
                if task.continueOnError == true {
                    printer.printFormatted("\(.raw("⚠️  Task '\(task.name)' exited \(exitCode) (continuing)"))")
                } else {
                    printer.printFormatted("\(.raw("✗ Task failed: \(task.name) (exit code \(exitCode))"))")
                    throw PipelineRunnerError.taskFailed(taskName: task.name, exitCode: exitCode)
                }
            }
        }

        let elapsed = Date().timeIntervalSince(start)
        let summary = "── Pipeline complete (\(tasks.count) task\(tasks.count == 1 ? "" : "s"), \(String(format: "%.1f", elapsed))s) "
        printer.printFormatted("\(.primary(summary + String(repeating: "─", count: max(0, 50 - summary.count))))")
    }

    // MARK: - Private

    private func printTaskHeader(index: Int, total: Int, name: String) {
        let label = "── Task \(index)/\(total): \(name) "
        let padding = String(repeating: "─", count: max(0, 60 - label.count))
        printer.printFormatted("\(.raw(label + padding))")
    }

    private func mergedEnvironment(pipelineEnv: [String: String]?, taskEnv: [String: String]?) -> [String: String] {
        var merged: [String: String] = [:]
        if let pipelineEnv { merged.merge(pipelineEnv) { _, new in new } }
        if let taskEnv { merged.merge(taskEnv) { _, new in new } }
        return merged
    }

    private func resolveWorkingDirectory(task: PipelineTask, pipeline: Pipeline, invocationDirectory: URL) -> URL? {
        guard let workDir = task.workingDirectory ?? pipeline.workingDirectory else { return nil }
        if workDir.hasPrefix("/") {
            return URL(fileURLWithPath: workDir)
        }
        return invocationDirectory.appending(path: workDir)
    }
}
