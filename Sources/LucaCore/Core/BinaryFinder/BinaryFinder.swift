//  BinaryFinder.swift

import Foundation

/// Locates the executable binary inside an extracted tool directory.
///
/// `BinaryFinder` walks the directory tree and identifies the first file
/// whose header magic matches a Mach-O or ELF binary.
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
                return "Could not enumerate directories at \(path)."
            case .missingBinaryFile(let location):
                return "Could not find binary at \(location)."
            }
        }
    }
    
    private let fileManager: BinaryFinderFileManaging
    
    init(fileManager: BinaryFinderFileManaging) {
        self.fileManager = fileManager
    }
    
    /// Searches the directory tree at `path` for the first Mach-O or ELF binary.
    /// - Parameter path: The root directory to search.
    /// - Returns: A relative path to the binary within the directory.
    func findBinary(atPath path: String) throws -> String {
        let url = URL(filePath: path, directoryHint: .isDirectory)
        // Normalize the base path with a trailing slash to safely strip the prefix later.
        // .producesRelativePathURLs is not honoured on Linux, so we compute the relative
        // path ourselves from the absolute path returned by the enumerator.
        let normalizedBasePath = url.path.hasSuffix("/") ? url.path : url.path + "/"
        
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
                    // ELF magic: 0x7F454C46 ("\x7FELF") — byte sequence is endian-independent
                    let elfMagic: UInt32 = 0x7F454C46
                    // Use loadUnaligned to avoid crashes on platforms with strict alignment (e.g. Linux)
                    let value = magic.withUnsafeBytes { $0.loadUnaligned(as: UInt32.self) }
                    if machOMagics.contains(value.bigEndian) || machOMagics.contains(value.littleEndian) || value.bigEndian == elfMagic {
                        // Prefer stripping the absolute base path so we always get a
                        // relative path regardless of whether .producesRelativePathURLs
                        // is honoured (it is silently ignored on Linux).
                        let absoluteFilePath = fileURL.path
                        if absoluteFilePath.hasPrefix(normalizedBasePath) {
                            return String(absoluteFilePath.dropFirst(normalizedBasePath.count))
                        }
                        return fileURL.relativePath
                    }
                }
            }
        }
        throw BinaryFinderError.missingBinaryFile(location: path)
    }
}
