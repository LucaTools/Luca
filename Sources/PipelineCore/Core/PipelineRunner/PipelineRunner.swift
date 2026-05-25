//  PipelineRunner.swift

import Foundation
import LucaFoundation
import Noora

/// Executes a ``Pipeline`` task by task, printing headers and streaming subprocess output.
///
/// Each task runs via `/usr/bin/env bash -c "set -eo pipefail && <command>"`.
/// Environment variables are merged in order: inherited process env ← pipeline-level env ← task-level env.
/// Working directory is resolved as: task-level → pipeline-level → invocation directory.
/// Tasks with a `when:` field are skipped when the condition evaluates to false.
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
    private let conditionEvaluator: TaskConditionEvaluating
    private let printer: Printing

    /// Creates a runner using the default subprocess executor and condition evaluator.
    public init(printer: Printing) {
        self.subprocessRunner = SubprocessRunner()
        self.conditionEvaluator = TaskConditionEvaluator()
        self.printer = printer
    }

    /// Creates a runner with custom subprocess executor and condition evaluator (used in tests).
    init(subprocessRunner: SubprocessRunning, conditionEvaluator: TaskConditionEvaluating, printer: Printing) {
        self.subprocessRunner = subprocessRunner
        self.conditionEvaluator = conditionEvaluator
        self.printer = printer
    }

    // MARK: - PipelineRunning

    public func run(_ pipeline: Pipeline, currentDirectoryURL: URL, parameters: [String: String]) async throws {
        let start = Date()
        let tasks = pipeline.tasks
        var executedCount = 0

        for (index, task) in tasks.enumerated() {
            printTaskHeader(index: index + 1, total: tasks.count, name: task.name)

            if let condition = task.when {
                let context = buildContext(parameters: parameters, pipelineEnv: pipeline.env, taskEnv: task.env)
                let shouldRun = conditionEvaluator.evaluate(condition: condition, context: context)
                if !shouldRun {
                    printer.printFormatted("⊘  \(.muted("Skipped (when: \(condition) → false)"))")
                    printer.printFormatted("\(.raw(""))")
                    continue
                }
            }

            let env = mergedEnvironment(pipelineEnv: pipeline.env, taskEnv: task.env)
            let workingDirectory = resolveWorkingDirectory(task: task, pipeline: pipeline, invocationDirectory: currentDirectoryURL)

            let command = renderCommand(task.command, parameters: parameters)
            let exitCode = try await subprocessRunner.run(
                executableURL: URL(fileURLWithPath: "/usr/bin/env"),
                arguments: ["bash", "-c", "set -eo pipefail && \(command)"],
                environment: env,
                workingDirectory: workingDirectory,
                inheritStdin: true
            )

            if exitCode != 0 {
                if task.continueOnError == true {
                    printer.printFormatted("⚠️  \(.muted("Task '"))\(.primary(task.name))\(.muted("' exited \(exitCode) (continuing)"))")
                } else {
                    printer.printFormatted("\(.danger("✗ Task failed: \(task.name) (exit code \(exitCode))"))")
                    throw PipelineRunnerError.taskFailed(taskName: task.name, exitCode: exitCode)
                }
            }

            executedCount += 1
            printer.printFormatted("\(.raw(""))")
        }

        let elapsed = Date().timeIntervalSince(start)
        let summary = "── Pipeline complete (\(executedCount) task\(executedCount == 1 ? "" : "s"), \(String(format: "%.1f", elapsed))s) "
        printer.printFormatted("\(.success(summary + String(repeating: "─", count: max(0, 60 - summary.count))))")
    }

    // MARK: - Private

    private func printTaskHeader(index: Int, total: Int, name: String) {
        let prefix = "── Task \(index)/\(total): "
        let padding = String(repeating: "─", count: max(0, 60 - prefix.count - name.count - 1))
        printer.printFormatted("\(.muted(prefix))\(.accent(name))\(.muted(" " + padding))")
    }

    private func buildContext(parameters: [String: String], pipelineEnv: [String: String]?, taskEnv: [String: String]?) -> [String: String] {
        var context: [String: String] = [:]
        if let pipelineEnv { context.merge(pipelineEnv) { _, new in new } }
        if let taskEnv { context.merge(taskEnv) { _, new in new } }
        context.merge(parameters) { _, new in new }
        return context
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

    private func renderCommand(_ command: String, parameters: [String: String]) -> String {
        parameters.reduce(command) { result, pair in
            result.replacingOccurrences(of: "${\(pair.key)}", with: pair.value)
        }
    }
}
