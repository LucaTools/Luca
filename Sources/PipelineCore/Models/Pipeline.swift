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
/// parameters:
///   - name: flavor
///     default: debug
/// env:
///   CI: "true"
/// working-directory: ios/
///
/// tasks:
///   - name: Generate project
///     command: tuist generate --platform ${flavor}
///   - name: Run backend tests
///     command: swift test
///     working-directory: backend/
/// ```
///
/// ## Topics
///
/// ### Properties
/// - ``tasks``
/// - ``parameters``
/// - ``env``
/// - ``workingDirectory``
///
/// ### Related Types
/// - ``PipelineTask``
/// - ``PipelineParameter``
/// - ``PipelineLoader``
/// - ``PipelineRunner``
public struct Pipeline: Codable {
    /// Ordered list of tasks to execute.
    public let tasks: [PipelineTask]
    /// Declared input parameters for this pipeline.
    /// Values are supplied at runtime via `--param name=value` and substituted into commands as `${name}`.
    public let parameters: [PipelineParameter]?
    /// Environment variables applied to every task unless overridden at the task level.
    public let env: [String: String]?
    /// Default working directory for all tasks.
    /// Relative paths are resolved against the directory where `luca run` was invoked.
    /// Task-level ``PipelineTask/workingDirectory`` overrides this value.
    public let workingDirectory: String?

    public init(tasks: [PipelineTask], env: [String: String]?, workingDirectory: String?, parameters: [PipelineParameter]? = nil) {
        self.tasks = tasks
        self.parameters = parameters
        self.env = env
        self.workingDirectory = workingDirectory
    }

    private enum CodingKeys: String, CodingKey {
        case tasks, parameters, env
        case workingDirectory = "working-directory"
    }
}
