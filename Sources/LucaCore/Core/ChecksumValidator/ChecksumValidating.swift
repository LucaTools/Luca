//  ChecksumValidating.swift

import Foundation

public enum ChecksumAlgorithm: String, Codable, CaseIterable, Sendable {
    case md5
    case sha1
    case sha256
    case sha512
}

protocol ChecksumValidating {
    func validate(checksum: String, for filePath: String, using algorithm: ChecksumAlgorithm) throws
}
