//  CalculateChecksumCommand.swift

import ArgumentParser
import Foundation
import LucaCore

/// Computes a checksum hash for a file, useful for generating Lucafile entries.
struct CalculateChecksumCommand: AsyncParsableCommand {
    
    static let configuration = CommandConfiguration(
        commandName: "calculate-checksum",
        abstract: "Calculate the checksum of a file.",
        discussion: """
        Computes a hash for integrity verification.
        Use this to generate checksums for Lucafile entries.
        """
    )
    
    @OptionGroup var commonFlags: CommonFlags

    @Argument(help: ArgumentHelp(
        "Path to the file to hash.",
        discussion: """
        Example:
          luca calculate-checksum ./downloads/tool.zip
        """,
        valueName: "path"
    ))
    var file: String
    
    @Option(help: ArgumentHelp(
        "Hash algorithm to use.",
        valueName: "algorithm"
    ))
    var algorithm: ChecksumAlgorithm = .sha256
    
    func run() async throws {
        let fileManager = FileManagerWrapper(fileManager: .default)
        let calculator = ChecksumCalculator(fileManager: fileManager)
        
        let checksum = try calculator.calculateChecksum(for: file, using: algorithm)
        print(checksum)
    }
}
