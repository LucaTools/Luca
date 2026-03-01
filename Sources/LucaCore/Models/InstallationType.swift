//  InstallationType.swift

import Foundation

/// Specifies the source from which tools are resolved for installation.
public enum InstallationType {
    /// Install all tools listed in a Lucafile at the given path.
    case spec(specPath: URL)
    /// Install a single tool identified by `"organization/repository@version"`.
    case individual(identifier: String, asset: String?, binaryPath: String?, desiredBinaryName : String?, checksum: String?, algorithm: ChecksumAlgorithm?)
    /// Install a single tool with all details supplied inline (no GitHub lookup).
    case individualInline(name: String, version: String, url: URL, binaryPath: String?, desiredBinaryName: String?, checksum: String?, algorithm: ChecksumAlgorithm?)
}
