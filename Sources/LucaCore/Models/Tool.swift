//  Tool.swift

import Foundation

/// A single installable tool (binary) described in the spec file.
struct Tool: Decodable {
    /// Logical name of the tool (used for directory hierarchy).
    let name: String
    /// Path (possibly nested) to the binary inside the unzipped archive.
    let binaryPath: String
    /// Version string (used to build folder names and allow side‑by‑side installs).
    let version: String
    /// Remote URL to a zip archive containing the tool.
    let zipUrl: String

    /// Basename of the binary derived from `binaryPath`.
    var binaryName: String {
        URL(fileURLWithPath: binaryPath)
            .lastPathComponent
    }

    /// Short descriptor combining name and version (used for temporary file names).
    var description: String {
        "\(name)-\(version)"
    }
}
