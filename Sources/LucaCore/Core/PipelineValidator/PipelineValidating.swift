//  PipelineValidating.swift

import Foundation

/// Validates that all tools referenced by a pipeline are available before execution.
public protocol PipelineValidating {
    /// Checks tool availability for every task in the pipeline and throws on the first missing tool.
    ///
    /// - Parameter pipeline: The pipeline to validate.
    /// - Throws: ``PipelineValidator/PipelineValidatorError/toolNotFound(taskName:tool:)`` if any required tool is absent from `PATH`.
    func validate(_ pipeline: Pipeline) throws
}
