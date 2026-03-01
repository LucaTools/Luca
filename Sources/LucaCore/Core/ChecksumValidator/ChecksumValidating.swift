//  ChecksumValidating.swift

import Foundation

/// The hashing algorithm to use when computing or verifying a checksum.
public enum ChecksumAlgorithm: String, Codable, CaseIterable, Sendable {
    /// MD5 (128-bit hash; insecure for cryptographic use, provided for compatibility).
    case md5
    /// SHA-1 (160-bit hash; insecure for cryptographic use, provided for compatibility).
    case sha1
    /// SHA-256 (256-bit hash; default algorithm).
    case sha256
    /// SHA-512 (512-bit hash).
    case sha512
}

/// Verifies a file's integrity by comparing its computed checksum against an expected value.
protocol ChecksumValidating {
    /// Computes the checksum of the file at `filePath` and compares it with `checksum`.
    /// - Parameters:
    ///   - checksum: The expected hex-encoded checksum string.
    ///   - filePath: The path to the file being validated.
    ///   - algorithm: The hashing algorithm to use.
    func validate(checksum: String, for filePath: String, using algorithm: ChecksumAlgorithm) throws
}
