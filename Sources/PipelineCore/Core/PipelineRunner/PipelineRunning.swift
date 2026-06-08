//  PipelineRunning.swift

import Foundation

/// Executes a ``Pipeline`` sequentially and reports progress.
public protocol PipelineRunning {
    /// Runs all tasks in the pipeline in order with parameter substitution applied to commands.
    ///
    /// - Parameters:
    ///   - pipeline: The pipeline to execute.
    ///   - currentDirectoryURL: The directory from which `luca run` was invoked; used to resolve relative working-directory paths.
    ///   - parameters: Resolved parameter values used to substitute `${name}` tokens in task commands.
    ///   - envFileEnvironment: Variables loaded from an `.env` file; merged before pipeline-level env so pipeline/task env can override them.
    func run(_ pipeline: Pipeline, currentDirectoryURL: URL, parameters: [String: String], envFileEnvironment: [String: String]) async throws
}

public extension PipelineRunning {
    /// Convenience overload with no env-file environment.
    func run(_ pipeline: Pipeline, currentDirectoryURL: URL, parameters: [String: String]) async throws {
        try await run(pipeline, currentDirectoryURL: currentDirectoryURL, parameters: parameters, envFileEnvironment: [:])
    }

    /// Convenience overload with no parameter substitution and no env-file environment.
    func run(_ pipeline: Pipeline, currentDirectoryURL: URL) async throws {
        try await run(pipeline, currentDirectoryURL: currentDirectoryURL, parameters: [:], envFileEnvironment: [:])
    }
}
