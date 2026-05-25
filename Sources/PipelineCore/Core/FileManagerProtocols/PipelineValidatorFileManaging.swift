//  PipelineValidatorFileManaging.swift

import Foundation

/// File system interface for ``PipelineValidator``.
public protocol PipelineValidatorFileManaging {
    /// Returns `true` if an executable file exists at the given path.
    func isExecutableFile(atPath path: String) -> Bool
}
