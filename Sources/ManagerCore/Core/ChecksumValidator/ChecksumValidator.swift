//  ChecksumValidator.swift

import Foundation
import LucaFoundation
import Crypto

/// Validates a file's integrity by comparing its computed hash against an expected checksum string.
struct ChecksumValidator: ChecksumValidating {

    enum ChecksumValidatorError: Error, LocalizedError, Equatable {
        case invalidChecksum(path: String)
        
        var errorDescription: String? {
            switch self {
            case .invalidChecksum(let path):
                return "Invalid checksum for file at path: \(path)"
            }
        }
    }
    
    private let calculator: ChecksumCalculator
    
    init(fileManager: ChecksumValidatorFileManaging) {
        self.calculator = ChecksumCalculator(fileManager: fileManager)
    }
    
    /// Computes the checksum of the file at `filePath` and compares it with `checksum`.
    func validate(checksum: String, for filePath: String, using algorithm: ChecksumAlgorithm) throws {
        let calculatedChecksum = try calculator.calculateChecksum(for: filePath, using: algorithm)
        guard calculatedChecksum.lowercased() == checksum.lowercased() else {
            throw ChecksumValidatorError.invalidChecksum(path: filePath)
        }
    }
}
