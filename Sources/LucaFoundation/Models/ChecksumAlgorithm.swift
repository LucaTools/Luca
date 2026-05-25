//  ChecksumAlgorithm.swift

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
