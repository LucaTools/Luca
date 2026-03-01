//  ArchitectureValidatorFileManaging.swift

import Foundation

/// File system interface for ``ArchitectureValidator``.
public protocol ArchitectureValidatorFileManaging {
    func contents(atPath path: String) -> Data?
    func fileExists(atPath: String) -> Bool
}
