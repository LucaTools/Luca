//  ChecksumValidatorFileManaging.swift

import Foundation

/// File system interface for ``ChecksumValidator``.
public protocol ChecksumValidatorFileManaging {
    func contents(atPath path: String) -> Data?
    func fileExists(atPath: String) -> Bool
}
