//  PipelineValidator.swift

import Foundation

/// Validates that all tools required by a pipeline are available on the machine.
///
/// For each task, checks the explicit ``PipelineTask/tools`` list when present;
/// otherwise validates the first whitespace-delimited token of ``PipelineTask/command``.
/// Validation searches each directory in `PATH` for an executable file.
public struct PipelineValidator: PipelineValidating {

    public enum PipelineValidatorError: Error, LocalizedError, Equatable {
        case toolNotFound(taskName: String, tool: String)

        public var errorDescription: String? {
            switch self {
            case .toolNotFound(let taskName, let tool):
                return "Task '\(taskName)' requires '\(tool)', which was not found in PATH."
            }
        }
    }

    /// A single tool availability result used for dry-run display.
    public struct ToolCheckResult {
        public let taskName: String
        public let tool: String
        public let available: Bool
    }

    private let fileManager: PipelineValidatorFileManaging
    private let pathEnvironment: String

    public init(fileManager: PipelineValidatorFileManaging, pathEnvironment: String = ProcessInfo.processInfo.environment["PATH"] ?? "") {
        self.fileManager = fileManager
        self.pathEnvironment = pathEnvironment
    }

    // MARK: - PipelineValidating

    /// Validates all tools; throws on the first unavailable tool.
    public func validate(_ pipeline: Pipeline) throws {
        for taskResults in toolCheckResults(for: pipeline) {
            for result in taskResults where !result.available {
                throw PipelineValidatorError.toolNotFound(taskName: result.taskName, tool: result.tool)
            }
        }
    }

    /// Returns per-task availability results (one inner array per task, in pipeline order).
    ///
    /// Used by dry-run output to display tool availability alongside each task.
    public func toolCheckResults(for pipeline: Pipeline) -> [[ToolCheckResult]] {
        pipeline.tasks.map { task in
            toolsToValidate(for: task).map { tool in
                ToolCheckResult(taskName: task.name, tool: tool, available: isAvailable(tool))
            }
        }
    }

    // MARK: - Private

    private func toolsToValidate(for task: PipelineTask) -> [String] {
        if let explicit = task.tools {
            return explicit
        }
        guard let first = task.command.split(separator: " ").first.map(String.init) else {
            return []
        }
        return [first]
    }

    private func isAvailable(_ tool: String) -> Bool {
        if tool.hasPrefix("/") || tool.hasPrefix("./") || tool.hasPrefix("../") {
            return fileManager.isExecutableFile(atPath: tool)
        }
        let paths = pathEnvironment.split(separator: ":").map(String.init)
        return paths.contains { dir in
            let fullPath = (dir as NSString).appendingPathComponent(tool)
            return fileManager.isExecutableFile(atPath: fullPath)
        }
    }
}
