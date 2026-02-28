//  ArchitectureValidator.swift

import Foundation

struct ArchitectureValidator: ArchitectureValidating {
    
    enum ArchitectureValidatorError: Error, LocalizedError, Equatable {
        case incompatibleArchitecture(binary: String, binaryArch: Architecture, hostArch: Architecture)
        case unableToReadBinary(path: String)
        case unknownArchitecture(path: String)
        
        var errorDescription: String? {
            switch self {
            case .incompatibleArchitecture(let binary, let binaryArch, let hostArch):
                return "Binary '\(binary)' has architecture \(binaryArch.rawValue) but this machine requires \(hostArch.rawValue)."
            case .unableToReadBinary(let path):
                return "Unable to read binary at path: \(path)"
            case .unknownArchitecture(let path):
                return "Unable to determine architecture for binary at path: \(path)"
            }
        }
    }
    
    // MARK: - Mach-O Constants
    
    /// Mach-O 64-bit magic number (little-endian)
    private static let MH_MAGIC_64: UInt32 = 0xFEEDFACF
    /// Mach-O 64-bit magic number (big-endian, reversed)
    private static let MH_CIGAM_64: UInt32 = 0xCFFAEDFE
    /// Mach-O 32-bit magic number (little-endian)
    private static let MH_MAGIC: UInt32 = 0xFEEDFACE
    /// Mach-O 32-bit magic number (big-endian, reversed)
    private static let MH_CIGAM: UInt32 = 0xCEFAEDFE
    /// Universal binary (fat) magic number (big-endian)
    private static let FAT_MAGIC: UInt32 = 0xCAFEBABE
    /// Universal binary (fat) magic number (little-endian, reversed)
    private static let FAT_CIGAM: UInt32 = 0xBEBAFECA
    /// Universal binary 64-bit magic number
    private static let FAT_MAGIC_64: UInt32 = 0xCAFEBABF
    /// Universal binary 64-bit magic number (reversed)
    private static let FAT_CIGAM_64: UInt32 = 0xBFBAFECA
    
    /// CPU type for x86_64 (includes CPU_ARCH_ABI64 flag)
    private static let CPU_TYPE_X86_64: UInt32 = 0x01000007
    /// CPU type for ARM64 (includes CPU_ARCH_ABI64 flag)
    private static let CPU_TYPE_ARM64: UInt32 = 0x0100000C
    
    // MARK: - ELF Constants
    
    /// ELF magic bytes: 0x7F followed by 'E', 'L', 'F'
    private static let ELF_MAGIC: [UInt8] = [0x7F, 0x45, 0x4C, 0x46]
    /// ELF data encoding: little-endian
    private static let ELFDATA2LSB: UInt8 = 1
    /// ELF data encoding: big-endian
    private static let ELFDATA2MSB: UInt8 = 2
    /// ELF e_machine value for x86_64
    private static let EM_X86_64: UInt16 = 0x3E
    /// ELF e_machine value for AArch64
    private static let EM_AARCH64: UInt16 = 0xB7
    
    private let fileManager: ArchitectureValidatorFileManaging
    
    init(fileManager: ArchitectureValidatorFileManaging) {
        self.fileManager = fileManager
    }
    
    // MARK: - ArchitectureValidating
    
    func validate(binaryPath: String) throws {
        let architecture = try detectArchitecture(at: binaryPath)
        
        guard architecture.isCompatibleWithHost else {
            let binaryName = URL(fileURLWithPath: binaryPath).lastPathComponent
            throw ArchitectureValidatorError.incompatibleArchitecture(
                binary: binaryName,
                binaryArch: architecture,
                hostArch: Architecture.host
            )
        }
    }
    
    func detectArchitecture(at binaryPath: String) throws -> Architecture {
        guard fileManager.fileExists(atPath: binaryPath),
              let data = fileManager.contents(atPath: binaryPath),
              data.count >= 8 else {
            throw ArchitectureValidatorError.unableToReadBinary(path: binaryPath)
        }
        
        let magic = data.withUnsafeBytes { $0.load(as: UInt32.self) }
        
        // Check if it's a universal (fat) binary
        if magic == Self.FAT_MAGIC || magic == Self.FAT_CIGAM ||
           magic == Self.FAT_MAGIC_64 || magic == Self.FAT_CIGAM_64 {
            return try detectFatBinaryArchitectures(data: data, magic: magic, path: binaryPath)
        }
        
        // Check if it's a single-architecture Mach-O
        if magic == Self.MH_MAGIC_64 || magic == Self.MH_CIGAM_64 ||
           magic == Self.MH_MAGIC || magic == Self.MH_CIGAM {
            return try detectMachOArchitecture(data: data, magic: magic, path: binaryPath)
        }
        
        // Check if it's an ELF binary
        if data.count >= 4 && data.prefix(4).elementsEqual(Self.ELF_MAGIC) {
            return try detectELFArchitecture(data: data, path: binaryPath)
        }
        
        throw ArchitectureValidatorError.unknownArchitecture(path: binaryPath)
    }
    
    // MARK: - Private
    
    private func detectMachOArchitecture(data: Data, magic: UInt32, path: String) throws -> Architecture {
        // CPU type is at offset 4 in the Mach-O header
        guard data.count >= 8 else {
            throw ArchitectureValidatorError.unableToReadBinary(path: path)
        }
        
        let needsSwap = (magic == Self.MH_CIGAM_64 || magic == Self.MH_CIGAM)
        
        let cpuType: UInt32 = data.withUnsafeBytes { buffer in
            let value = buffer.load(fromByteOffset: 4, as: UInt32.self)
            return needsSwap ? value.byteSwapped : value
        }
        
        return try architectureFromCPUType(cpuType, path: path)
    }
    
    private func detectFatBinaryArchitectures(data: Data, magic: UInt32, path: String) throws -> Architecture {
        // Fat header: magic (4 bytes) + nfat_arch (4 bytes)
        guard data.count >= 8 else {
            throw ArchitectureValidatorError.unableToReadBinary(path: path)
        }
        
        let needsSwap = (magic == Self.FAT_CIGAM || magic == Self.FAT_CIGAM_64)
        let is64BitFat = (magic == Self.FAT_MAGIC_64 || magic == Self.FAT_CIGAM_64)
        
        let nfatArch: UInt32 = data.withUnsafeBytes { buffer in
            let value = buffer.load(fromByteOffset: 4, as: UInt32.self)
            return needsSwap ? value.byteSwapped : value
        }
        
        // fat_arch struct: cputype (4), cpusubtype (4), offset (4/8), size (4/8), align (4)
        // For 32-bit fat: struct is 20 bytes
        // For 64-bit fat: struct is 32 bytes
        let fatArchSize = is64BitFat ? 32 : 20
        let headerSize = 8
        
        var architectures: [Architecture] = []
        
        for i in 0..<Int(nfatArch) {
            let archOffset = headerSize + (i * fatArchSize)
            guard data.count >= archOffset + 4 else { continue }
            
            let cpuType: UInt32 = data.withUnsafeBytes { buffer in
                let value = buffer.load(fromByteOffset: archOffset, as: UInt32.self)
                return needsSwap ? value.byteSwapped : value
            }
            
            if let arch = try? architectureFromCPUType(cpuType, path: path) {
                architectures.append(arch)
            }
        }
        
        // If we found multiple architectures, it's a universal binary
        if architectures.count > 1 {
            return .universal
        }
        
        // If we found exactly one, return it
        if let first = architectures.first {
            return first
        }
        
        throw ArchitectureValidatorError.unknownArchitecture(path: path)
    }
    
    private func architectureFromCPUType(_ cpuType: UInt32, path: String) throws -> Architecture {
        switch cpuType {
        case Self.CPU_TYPE_ARM64:
            return .arm64
        case Self.CPU_TYPE_X86_64:
            return .x86_64
        default:
            throw ArchitectureValidatorError.unknownArchitecture(path: path)
        }
    }
    
    /// Detects the architecture of an ELF binary.
    ///
    /// ELF header layout:
    /// - Bytes 0–3: magic `\x7fELF`
    /// - Byte 5: data encoding (1 = little-endian, 2 = big-endian)
    /// - Bytes 18–19: `e_machine` (in the encoding specified by byte 5)
    private func detectELFArchitecture(data: Data, path: String) throws -> Architecture {
        // Need at least 20 bytes: 16-byte ELF ident + 2 (e_type) + 2 (e_machine)
        guard data.count >= 20 else {
            throw ArchitectureValidatorError.unableToReadBinary(path: path)
        }
        
        let dataEncoding = data[5]
        
        let eMachine: UInt16 = data.withUnsafeBytes { buffer in
            let raw = buffer.load(fromByteOffset: 18, as: UInt16.self)
            switch dataEncoding {
            case Self.ELFDATA2MSB:
                return UInt16(bigEndian: raw)
            default: // ELFDATA2LSB or unknown — assume little-endian
                return UInt16(littleEndian: raw)
            }
        }
        
        switch eMachine {
        case Self.EM_X86_64:
            return .x86_64
        case Self.EM_AARCH64:
            return .aarch64
        default:
            throw ArchitectureValidatorError.unknownArchitecture(path: path)
        }
    }
}
