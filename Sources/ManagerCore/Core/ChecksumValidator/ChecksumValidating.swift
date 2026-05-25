//  ChecksumValidating.swift

import Foundation
import LucaFoundation

/// Verifies a file's integrity by comparing its computed checksum against an expected value.
protocol ChecksumValidating {
    /// Computes the checksum of the file at `filePath` and compares it with `checksum`.
    /// - Parameters:
    ///   - checksum: The expected hex-encoded checksum string.
    ///   - filePath: The path to the file being validated.
    ///   - algorithm: The hashing algorithm to use.
    func validate(checksum: String, for filePath: String, using algorithm: ChecksumAlgorithm) throws
}
