//  ArchitectureValidating.swift

import Foundation

protocol ArchitectureValidating {
    /// Validates that the binary at the given path is compatible with the host machine's architecture.
    /// - Parameter binaryPath: The path to the binary file to validate.
    /// - Throws: `ArchitectureValidatorError.incompatibleArchitecture` if the binary is not compatible.
    func validate(binaryPath: String) throws
    
    /// Detects the architecture of the binary at the given path.
    /// - Parameter binaryPath: The path to the binary file.
    /// - Returns: The detected `Architecture` of the binary.
    /// - Throws: `ArchitectureValidatorError.unableToReadBinary` if the binary cannot be read.
    func detectArchitecture(at binaryPath: String) throws -> Architecture
}
