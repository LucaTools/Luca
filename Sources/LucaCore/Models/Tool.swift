//  Tool.swift

import Foundation

/// A single installable tool (binary) described in the spec file.
struct Tool: Codable {
    /// Logical name of the tool (used for directory hierarchy).
    let name: String
    /// Version string (used to build folder names and allow side‑by‑side installs).
    let version: String
    /// Remote URL to an archive containing the tool or an executable file.
    let url: URL
    /// Path (possibly nested) to the binary inside the unzipped archive.
    let binaryPath: String?
    /// Name of the binary stored locally. Requires `url` to point to an executable file, ignored otherwise.
    let desiredBinaryName: String?
    /// The checksum hash of asset associated with the tool.
    let checksum: String?
    /// The algorithm used to generate the checksum.
    let algorithm: ChecksumAlgorithm?
}

extension Tool {
    /// Resolves the expected binary name for comparison with linked tools.
    /// Priority: desiredBinaryName > binaryPath basename > tool name.
    var expectedBinaryName: String {
        if let desiredBinaryName { return desiredBinaryName }
        if let binaryPath { return URL(fileURLWithPath: binaryPath).lastPathComponent }
        return name
    }
}

struct EnrichedTool: Codable {
    /// Logical name of the tool (used for directory hierarchy).
    let name: String
    /// Version string (used to build folder names and allow side‑by‑side installs).
    let version: String
    /// Remote URL to an archive containing the tool or an executable file.
    let url: URL
    /// Path (possibly nested) to the binary inside the unzipped archive.
    let binaryPath: String
    /// Name of the binary stored locally. Requires `url` to point to an executable file, ignored otherwise.
    let desiredBinaryName: String?
    /// The checksum hash of asset associated with the tool.
    let checksum: String?
    /// The algorithm used to generate the checksum.
    let algorithm: ChecksumAlgorithm?
    
    /// Basename of the binary derived from `binaryPath` if available, otherwise falls back to `name`.
    var binaryName: String {
        if let desiredBinaryName {
            return desiredBinaryName
        }
        return URL(fileURLWithPath: binaryPath)
            .lastPathComponent
    }
}
