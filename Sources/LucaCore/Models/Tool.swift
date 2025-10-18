//  Tool.swift

import Foundation

/// A single installable tool (binary) described in the spec file.
struct Tool: Codable {
    /// Logical name of the tool (used for directory hierarchy).
    let name: String
    /// Version string (used to build folder names and allow side‑by‑side installs).
    let version: String
    /// Remote URL to an archive containing the tool.
    let url: URL
    /// Path (possibly nested) to the binary inside the unzipped archive.
    let binaryPath: String?
    /// The checksum hash of asset associated with the tool.
    let checksum: String?
    /// The algorithm used to generate the checksum.
    let algorithm: ChecksumAlgorithm?
}

struct EnrichedTool: Codable {
    /// Logical name of the tool (used for directory hierarchy).
    let name: String
    /// Version string (used to build folder names and allow side‑by‑side installs).
    let version: String
    /// Remote URL to a zip archive containing the tool.
    let url: URL
    /// Path (possibly nested) to the binary inside the unzipped archive.
    let binaryPath: String
    /// The checksum hash of asset associated with the tool.
    let checksum: String?
    /// The algorithm used to generate the checksum.
    let algorithm: ChecksumAlgorithm?
    
    /// Basename of the binary derived from `binaryPath` if available, otherwise falls back to `name`.
    var binaryName: String {
        URL(fileURLWithPath: binaryPath)
            .lastPathComponent
    }
}
