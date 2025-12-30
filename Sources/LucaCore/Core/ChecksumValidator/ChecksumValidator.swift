//  ChecksumValidator.swift

import Foundation
import Crypto

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
    
    func validate(checksum: String, for filePath: String, using algorithm: ChecksumAlgorithm) throws {
        let calculatedChecksum = try calculator.calculateChecksum(for: filePath, using: algorithm)
        guard calculatedChecksum.lowercased() == checksum.lowercased() else {
            throw ChecksumValidatorError.invalidChecksum(path: filePath)
        }
    }
}
