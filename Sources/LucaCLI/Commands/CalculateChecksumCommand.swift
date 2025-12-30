//  CalculateChecksumCommand.swift

import ArgumentParser
import Foundation
import LucaCore

struct CalculateChecksumCommand: AsyncParsableCommand {
    
    static let configuration = CommandConfiguration(
        commandName: "calculate-checksum",
        abstract: "Calculates the checksum of a file."
    )
    
    @Argument(help: "The path to the file.")
    var file: String
    
    @Option(help: "The algorithm to use.")
    var algorithm: ChecksumAlgorithm = .sha256
    
    func run() async throws {
        let fileManager = FileManagerWrapper(fileManager: .default)
        let calculator = ChecksumCalculator(fileManager: fileManager)
        
        let checksum = try calculator.calculateChecksum(for: file, using: algorithm)
        print(checksum)
    }
}
