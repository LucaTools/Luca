//  PipelineLoading.swift

import Foundation

/// Loads and decodes pipeline YAML files into ``Pipeline`` values.
public protocol PipelineLoading {
    /// Loads a pipeline from the specified file path.
    ///
    /// - Parameter path: URL to the pipeline YAML file.
    /// - Returns: A ``Pipeline`` containing the parsed task definitions.
    func loadPipeline(at path: URL) throws -> Pipeline
}
