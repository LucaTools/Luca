//  InstallationType.swift

import Foundation

public enum InstallationType {
    case spec(specPath: URL)
    case individual(identifier: String, asset: String?, binaryPath: String?, desiredBinaryName : String?, checksum: String?, algorithm: ChecksumAlgorithm?)
    case individualInline(name: String, version: String, url: URL, binaryPath: String?, desiredBinaryName: String?, checksum: String?, algorithm: ChecksumAlgorithm?)
}
