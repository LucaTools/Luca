//  Pipeline.swift

import Foundation

/// A pipeline definition loaded from a YAML file.
///
/// A `Pipeline` contains an ordered list of ``PipelineTask`` values executed sequentially by ``PipelineRunner``.
///
/// ## Pipeline File Example
///
/// ```yaml
/// ---
/// env:
///   CI: "true"
/// working-directory: ios/
///
/// tasks:
///   - name: Generate project
///     command: tuist generate
///   - name: Run backend tests
///     command: swift test
///     working-directory: backend/
/// ```
///
/// ## Topics
///
/// ### Properties
/// - ``tasks``
/// - ``env``
/// - ``workingDirectory``
///
/// ### Related Types
/// - ``PipelineTask``
/// - ``PipelineLoader``
/// - ``PipelineRunner``
public struct Pipeline: Codable {
    /// Ordered list of tasks to execute.
    public let tasks: [PipelineTask]
    /// Environment variables applied to every task unless overridden at the task level.
    public let env: [String: String]?
    /// Default working directory for all tasks.
    /// Relative paths are resolved against the directory where `luca run` was invoked.
    /// Task-level ``PipelineTask/workingDirectory`` overrides this value.
    public let workingDirectory: String?

    public init(tasks: [PipelineTask], env: [String: String]?, workingDirectory: String?) {
        self.tasks = tasks
        self.env = env
        self.workingDirectory = workingDirectory
    }

    private enum CodingKeys: String, CodingKey {
        case tasks, env
        case workingDirectory = "working-directory"
    }
}
