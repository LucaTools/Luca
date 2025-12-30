//  ChecksumCalculator.swift

import Foundation
import Crypto

public struct ChecksumCalculator {
    
    public enum ChecksumCalculatorError: Error, LocalizedError, Equatable {
        case invalidFile(path: String)
        case missingFile(path: String)
        
        public var errorDescription: String? {
            switch self {
            case .invalidFile(let path):
                return "Invalid file at path: \(path)"
            case .missingFile(let path):
                return "File not found at path: \(path)"
            }
        }
    }
    
    private let fileManager: ChecksumValidatorFileManaging
    
    public init(fileManager: ChecksumValidatorFileManaging) {
        self.fileManager = fileManager
    }
    
    public func calculateChecksum(for filePath: String, using algorithm: ChecksumAlgorithm) throws(ChecksumCalculatorError) -> String {
        guard fileManager.fileExists(atPath: filePath) else {
            throw ChecksumCalculatorError.missingFile(path: filePath)
        }
        guard let fileData = fileManager.contents(atPath: filePath) else {
            throw ChecksumCalculatorError.invalidFile(path: filePath)
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
