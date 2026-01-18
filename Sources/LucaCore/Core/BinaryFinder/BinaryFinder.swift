//  BinaryFinder.swift

import Foundation

struct BinaryFinder: BinaryFinding {
    
    enum BinaryFinderError: Error, LocalizedError, Equatable {
        case cannotConstructUrl(path: String)
        case cannotEnumerateDirectory(path: String)
        case missingBinaryFile(location: String)

        var errorDescription: String? {
            switch self {
            case .cannotConstructUrl(let path):
                return "Cannot construct URL from String '\(path)'."
            case .cannotEnumerateDirectory(let path):
                return "Could not enumerate directories at \(path)"
            case .missingBinaryFile(let location):
                return "Could not find binary at \(location)."
            }
        }
    }
    
    private let fileManager: BinaryFinderFileManaging
    
    init(fileManager: BinaryFinderFileManaging) {
        self.fileManager = fileManager
    }
    
    func findBinary(atPath path: String) throws -> String {
        let url = URL(filePath: path, directoryHint: .isDirectory)
        
        guard let directoryEnumerator = fileManager.enumerator(at: url, includingPropertiesForKeys: [.isRegularFileKey, .isExecutableKey], options: [.producesRelativePathURLs, .skipsHiddenFiles]) else {
            throw BinaryFinderError.cannotEnumerateDirectory(path: path)
        }

        for case let fileURL as URL in directoryEnumerator {
            let resourceValues = try fileURL.resourceValues(forKeys: [.isRegularFileKey, .isExecutableKey])
            if resourceValues.isRegularFile == true && resourceValues.isExecutable == true {
                // Check if the file is a Mach-O binary (for macOS/iOS)
                let fileHandle = try FileHandle(forReadingFrom: fileURL)
                defer { try? fileHandle.close() }
                let magic = try fileHandle.read(upToCount: 4)
                if let magic = magic, magic.count == 4 {
                    // Mach-O magic numbers: 0xFEEDFACE, 0xFEEDFACF, 0xCAFEBABE (fat), 0xCEFAEDFE, 0xCFFAEDFE
                    let machOMagics: [UInt32] = [
                        0xFEEDFACE, 0xFEEDFACF, 0xCAFEBABE, 0xCEFAEDFE, 0xCFFAEDFE
                    ]
                    let value = magic.withUnsafeBytes { $0.load(as: UInt32.self) }
                    if machOMagics.contains(value.bigEndian) || machOMagics.contains(value.littleEndian) {
                        return fileURL.relativePath
                    }
                }
            }
        }
        throw BinaryFinderError.missingBinaryFile(location: path)
    }
}
