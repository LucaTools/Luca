//  PipelineTask.swift

import Foundation

/// A single shell task within a ``Pipeline``.
///
/// ## Example
///
/// ```yaml
/// - name: Generate project
///   command: tuist generate
///   env:
///     DEVELOPER_DIR: /Applications/Xcode.app
///   working-directory: ios/
///   when: ${flavor} == release
/// ```
///
/// ## Topics
///
/// ### Properties
/// - ``name``
/// - ``command``
/// - ``tools``
/// - ``env``
/// - ``continueOnError``
/// - ``workingDirectory``
/// - ``when``
public struct PipelineTask: Codable {
    /// Human-readable label displayed in the terminal before the task executes.
    public let name: String
    /// Shell command to execute (e.g. `tuist generate` or `swift build`).
    public let command: String
    /// Explicit list of tools to validate before execution.
    /// When `nil`, the first whitespace-delimited token of ``command`` is validated instead.
    public let tools: [String]?
    /// Environment variables merged on top of the pipeline-level env and the inherited process environment.
    public let env: [String: String]?
    /// When `true`, a non-zero exit code from this task is logged as a warning and execution continues.
    public let continueOnError: Bool?
    /// Working directory for this task.
    /// Relative paths are resolved against the directory where `luca run` was invoked.
    /// Overrides the pipeline-level ``Pipeline/workingDirectory``.
    public let workingDirectory: String?
    /// Optional condition expression. The task is skipped when this evaluates to false.
    /// Supports `${name} == value`, `${name} != value`, and plain truthy `${name}` forms.
    public let when: String?

    public init(name: String, command: String, tools: [String]?, env: [String: String]?, continueOnError: Bool?, workingDirectory: String?, when: String? = nil) {
        self.name = name
        self.command = command
        self.tools = tools
        self.env = env
        self.continueOnError = continueOnError
        self.workingDirectory = workingDirectory
        self.when = when
    }

    private enum CodingKeys: String, CodingKey {
        case name, command, tools, env, when
        case continueOnError = "continue-on-error"
        case workingDirectory = "working-directory"
    }
}
