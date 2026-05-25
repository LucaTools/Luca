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
    func run(_ pipeline: Pipeline, currentDirectoryURL: URL, parameters: [String: String]) async throws
}

public extension PipelineRunning {
    /// Convenience overload with no parameter substitution.
    func run(_ pipeline: Pipeline, currentDirectoryURL: URL) async throws {
        try await run(pipeline, currentDirectoryURL: currentDirectoryURL, parameters: [:])
    }
}
