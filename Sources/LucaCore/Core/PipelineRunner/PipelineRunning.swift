//  PipelineRunning.swift

import Foundation

/// Executes a ``Pipeline`` sequentially and reports progress.
public protocol PipelineRunning {
    /// Runs all tasks in the pipeline in order, stopping on the first failure unless `continue-on-error` is set.
    ///
    /// - Parameters:
    ///   - pipeline: The pipeline to execute.
    ///   - currentDirectoryURL: The directory from which `luca run` was invoked; used to resolve relative working-directory paths.
    func run(_ pipeline: Pipeline, currentDirectoryURL: URL) async throws
}
