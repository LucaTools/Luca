//  PipelineRunner.swift

import Foundation
import LucaFoundation
import Noora

/// Executes a ``Pipeline`` task by task, printing headers and streaming subprocess output.
///
/// Each task runs via `/usr/bin/env bash -c "set -eo pipefail && <command>"`.
/// Environment variables are merged in order: inherited process env ← env-file env ← pipeline-level env ← task-level env.
/// Working directory is resolved as: task-level → pipeline-level → invocation directory.
/// Tasks with a `when:` field are skipped when the condition evaluates to false.
///
/// Parameters are **not** interpolated as literal text into the command. Instead each parameter is
/// exposed to the shell as an environment variable (`LUCA_PARAM_<name>`) and every `${name}`
/// placeholder is rewritten to a quoted shell reference (`"${LUCA_PARAM_name}"`). Because bash does
/// not re-parse the result of a parameter expansion, a value such as `; rm -rf ~` is passed through
/// as inert data rather than being executed — closing the command-injection vector that literal
/// substitution would otherwise open.
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

    public func run(_ pipeline: Pipeline, currentDirectoryURL: URL, parameters: [String: String], envFileEnvironment: [String: String]) async throws {
        let start = Date()
        let tasks = pipeline.tasks
        var executedCount = 0

        // Expose parameters as namespaced environment variables and map each `${name}`
        // placeholder to a quoted shell reference, so values are never parsed as shell code.
        let (parameterEnvironment, parameterReferences) = parameterBindings(parameters)

        for (index, task) in tasks.enumerated() {
            printTaskHeader(index: index + 1, total: tasks.count, name: task.name)

            if let condition = task.when {
                let context = buildContext(parameters: parameters, envFileEnvironment: envFileEnvironment, pipelineEnv: pipeline.env, taskEnv: task.env)
                let shouldRun = conditionEvaluator.evaluate(condition: condition, context: context)
                if !shouldRun {
                    printer.printFormatted("⊘  \(.muted("Skipped (when: \(condition) → false)"))")
                    printer.printFormatted("\(.raw(""))")
                    continue
                }
            }

            var env = mergedEnvironment(envFileEnvironment: envFileEnvironment, pipelineEnv: pipeline.env, taskEnv: task.env)
            env.merge(parameterEnvironment) { _, new in new }
            let workingDirectory = resolveWorkingDirectory(task: task, pipeline: pipeline, invocationDirectory: currentDirectoryURL)

            let command = renderCommand(task.command, parameterReferences: parameterReferences)
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

    private func buildContext(parameters: [String: String], envFileEnvironment: [String: String], pipelineEnv: [String: String]?, taskEnv: [String: String]?) -> [String: String] {
        var context: [String: String] = [:]
        context.merge(envFileEnvironment) { _, new in new }
        if let pipelineEnv { context.merge(pipelineEnv) { _, new in new } }
        if let taskEnv { context.merge(taskEnv) { _, new in new } }
        context.merge(parameters) { _, new in new }
        return context
    }

    private func mergedEnvironment(envFileEnvironment: [String: String], pipelineEnv: [String: String]?, taskEnv: [String: String]?) -> [String: String] {
        var merged: [String: String] = [:]
        merged.merge(envFileEnvironment) { _, new in new }
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

    /// Replaces each `${name}` placeholder with a quoted reference to its environment variable.
    ///
    /// - Parameters:
    ///   - command: The raw task command.
    ///   - parameterReferences: Maps a parameter name to the environment-variable name holding its value.
    /// - Returns: The command with placeholders rewritten as `"${LUCA_PARAM_name}"`.
    private func renderCommand(_ command: String, parameterReferences: [String: String]) -> String {
        parameterReferences.reduce(command) { result, pair in
            result.replacingOccurrences(of: "${\(pair.key)}", with: "\"${\(pair.value)}\"")
        }
    }

    /// Builds the environment variables and placeholder references used to pass parameters to the shell.
    ///
    /// - Parameter parameters: The user-supplied parameter values.
    /// - Returns: A tuple of `(environment, references)` where `environment` maps each
    ///   `LUCA_PARAM_<name>` variable to its value, and `references` maps each original parameter
    ///   name to the environment-variable name it resolves to.
    private func parameterBindings(_ parameters: [String: String]) -> (environment: [String: String], references: [String: String]) {
        var environment: [String: String] = [:]
        var references: [String: String] = [:]
        var used: Set<String> = []

        // Sort for deterministic name assignment when two keys sanitize to the same identifier.
        for key in parameters.keys.sorted() {
            let base = environmentVariableName(for: key)
            var name = base
            var suffix = 2
            while used.contains(name) {
                name = "\(base)_\(suffix)"
                suffix += 1
            }
            used.insert(name)
            references[key] = name
            environment[name] = parameters[key]
        }

        return (environment, references)
    }

    /// Derives a shell-safe, namespaced environment-variable name from a parameter name.
    ///
    /// Any character that is not an ASCII letter, digit, or underscore is replaced with `_`,
    /// guaranteeing a valid shell identifier regardless of the original parameter name.
    private func environmentVariableName(for key: String) -> String {
        let sanitized = key.map { character -> Character in
            let isSafe = character.isASCII && (character.isLetter || character.isNumber || character == "_")
            return isSafe ? character : "_"
        }
        return "LUCA_PARAM_" + String(sanitized)
    }
}
