//  Tool.swift

import Foundation

/// A single installable tool (binary) described in the spec file.
///
/// A `Tool` represents a command-line tool that can be downloaded, installed,
/// and linked by Luca. Each tool is identified by a name and version, and
/// includes information about where to download it and how to locate the
/// binary within the downloaded archive.
///
/// ## Example
///
/// ```yaml
/// - name: SwiftLint
///   version: 0.61.0
///   url: https://github.com/realm/SwiftLint/releases/download/0.61.0/SwiftLintBinary.artifactbundle.zip
///   binaryPath: SwiftLintBinary.artifactbundle/swiftlint-0.61.0-macos/bin/swiftlint
/// ```
///
/// ## Topics
///
/// ### Required Properties
/// - ``name``
/// - ``version``
/// - ``url``
///
/// ### Optional Properties
/// - ``binaryPath``
/// - ``desiredBinaryName``
/// - ``checksum``
/// - ``algorithm``
/// - ``ignoreArchCheck``
///
/// ### Computed Properties
/// - ``expectedBinaryName``
/// - ``effectiveBinaryPath``
public struct Tool: Codable {
    /// Logical name of the tool (used for directory hierarchy).
    public let name: String
    /// Version string (used to build folder names and allow side‑by‑side installs).
    public let version: String
    /// Remote URL to an archive containing the tool or an executable file.
    public let url: URL
    /// Path (possibly nested) to the binary inside the unzipped archive.
    public let binaryPath: String?
    /// Name of the binary stored locally. Requires `url` to point to an executable file, ignored otherwise.
    public let desiredBinaryName: String?
    /// The checksum hash of asset associated with the tool.
    public let checksum: String?
    /// The algorithm used to generate the checksum.
    public let algorithm: ChecksumAlgorithm?
    /// Per-tool override for architecture validation.
    /// `true` always skips; `false` always validates; `nil` falls back to the CLI `--ignore-arch-check` flag.
    public let ignoreArchCheck: Bool?

    public init(
        name: String,
        version: String,
        url: URL,
        binaryPath: String? = nil,
        desiredBinaryName: String? = nil,
        checksum: String? = nil,
        algorithm: ChecksumAlgorithm? = nil,
        ignoreArchCheck: Bool? = nil
    ) {
        self.name = name
        self.version = version
        self.url = url
        self.binaryPath = binaryPath
        self.desiredBinaryName = desiredBinaryName
        self.checksum = checksum
        self.algorithm = algorithm
        self.ignoreArchCheck = ignoreArchCheck
    }
}

extension Tool {
    /// Resolves the expected binary name for comparison with linked tools.
    /// Priority: desiredBinaryName > binaryPath basename > tool name.
    public var expectedBinaryName: String {
        if let desiredBinaryName { return desiredBinaryName }
        if let binaryPath { return URL(fileURLWithPath: binaryPath).lastPathComponent }
        return name
    }

    /// Resolves the path to the binary file within the tool's installation directory.
    /// Priority: desiredBinaryName > binaryPath > name.
    public var effectiveBinaryPath: String {
        desiredBinaryName ?? binaryPath ?? name
    }
}
