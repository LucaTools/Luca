//  ChecksumValidator.swift

import Foundation
import Crypto

struct ChecksumValidator: ChecksumValidating {
    
    enum ChecksumValidatorError: Error, LocalizedError, Equatable {
        case invalidChecksum(path: String)
        case invalidFile(path: String)
        case missingFile(path: String)
        
        var errorDescription: String? {
            switch self {
            case .invalidChecksum(let path):
                return "Invalid checksum for file at path: \(path)"
            case .invalidFile(let path):
                return "Invalid file at path: \(path)"
            case .missingFile(let path):
                return "File not found at path: \(path)"
            }
        }
    }
    
    private let fileManager: ChecksumValidatorFileManaging
    
    init(fileManager: ChecksumValidatorFileManaging) {
        self.fileManager = fileManager
    }
    
    func validate(checksum: String, for filePath: String, using algorithm: ChecksumAlgorithm) throws(ChecksumValidatorError) {
        let calculatedChecksum = try checksumForFile(at: filePath, using: algorithm)
        guard calculatedChecksum.lowercased() == checksum.lowercased() else {
            throw ChecksumValidatorError.invalidChecksum(path: filePath)
        }
    }
    
    // MARK: Private
    
    private func checksumForFile(at filePath: String, using algorithm: ChecksumAlgorithm) throws(ChecksumValidatorError) -> String {
        guard fileManager.fileExists(atPath: filePath) else {
            throw ChecksumValidatorError.missingFile(path: filePath)
        }
        guard let fileData = fileManager.contents(atPath: filePath) else {
            throw ChecksumValidatorError.invalidFile(path: filePath)
        }
        
        let bytes = digest(data: fileData, algorithm: algorithm)
        return bytes.map { String(format: "%02x", $0) }.joined()
    }
    
    private func digest(data: Data, algorithm: ChecksumAlgorithm) -> [UInt8] {
        switch algorithm {
        case .md5: return Array(Crypto.Insecure.MD5.hash(data: data).makeIterator())
        case .sha1: return Array(Crypto.Insecure.SHA1.hash(data: data).makeIterator())
        case .sha256: return Array(Crypto.SHA256.hash(data: data).makeIterator())
        case .sha512: return Array(Crypto.SHA512.hash(data: data).makeIterator())
        }
    }
}
