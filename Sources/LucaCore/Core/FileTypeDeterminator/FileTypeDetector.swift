//  FileTypeDetector.swift

import Foundation

struct FileTypeDetector {
    
    let fileManager: FileTypeDetectorFileManaging
    
    func detectFileType(at filePath: URL) throws -> FileType {
        // Check the file signature (magic numbers)
        let fileHandle = try FileHandle(forReadingFrom: filePath)
        defer { fileHandle.closeFile() }
        
        let magicNumbers = try fileHandle.read(upToCount: 4) ?? Data()
        
        // Check if it's a zip file (PK magic number)
        if magicNumbers.count >= 2 && magicNumbers[0] == 0x50 && magicNumbers[1] == 0x4B {
            return .zip
        }
        
        // Check if it's executable
        // Cannot use 'test -x' as files might not have executable permissions set when downloaded from the Internet
        let fileAttributes = try fileManager.attributesOfItem(atPath: filePath.path)
        if let fileType = fileAttributes[.type] as? FileAttributeType,
           fileType == FileAttributeType.typeRegular {
            // Check if it's an executable binary by examining file headers
            let fileHandle = try FileHandle(forReadingFrom: filePath)
            defer { fileHandle.closeFile() }
            
            let headerData = try fileHandle.read(upToCount: 16) ?? Data()
            
            // Check for common executable magic numbers
            if headerData.count >= 4 {
                // Mach-O executables (macOS)
                if headerData.starts(with: [0xFE, 0xED, 0xFA, 0xCE]) ||  // 32-bit
                    headerData.starts(with: [0xFE, 0xED, 0xFA, 0xCF]) ||  // 64-bit
                    headerData.starts(with: [0xCE, 0xFA, 0xED, 0xFE]) ||  // 32-bit reverse
                    headerData.starts(with: [0xCF, 0xFA, 0xED, 0xFE]) {   // 64-bit reverse
                    return .executable
                }
                
                // ELF executables (Linux)
                if headerData.starts(with: [0x7F, 0x45, 0x4C, 0x46]) {
                    return .executable
                }
                
                // PE executables (Windows) - check for MZ signature and PE header
                if headerData.starts(with: [0x4D, 0x5A]) {
                    return .executable
                }
            }
        }
        
        // If we can't determine from the above, check the file extension
        if filePath.pathExtension.lowercased() == "zip" {
            return .zip
        }
        
        return .unknown
    }
}
