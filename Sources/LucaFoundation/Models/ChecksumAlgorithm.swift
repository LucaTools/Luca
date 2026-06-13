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

    /// Whether the algorithm is considered cryptographically broken for integrity verification.
    ///
    /// MD5 and SHA-1 are vulnerable to practical collision attacks, so a determined attacker can
    /// craft a malicious artifact that matches a published MD5/SHA-1 checksum. They remain selectable
    /// for compatibility with upstreams that only publish these digests, but callers should warn.
    public var isCryptographicallyWeak: Bool {
        switch self {
        case .md5, .sha1:
            return true
        case .sha256, .sha512:
            return false
        }
    }
}
