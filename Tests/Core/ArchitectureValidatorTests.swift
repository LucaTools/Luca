//  ArchitectureValidatorTests.swift

import Foundation
import Testing
@testable import LucaCore

struct ArchitectureValidatorTests {
    
    enum ArchitectureValidatorTestsError: Error, LocalizedError, Equatable {
        case unknownHostArchitecture
        
        var errorDescription: String? {
            switch self {
            case .unknownHostArchitecture:
                return "Unable to determine architecture for host"
            }
        }
    }
    
    private let fileManager = FileManager.default
    
    // MARK: - Architecture Model Tests
    
    @Test
    func hostArchitecture_returnsValidArchitecture() {
        let host = Architecture.host
        #expect(host == .arm64 || host == .x86_64)
    }
    
    @Test
    func universalArchitecture_isAlwaysCompatible() {
        #if os(Linux)
        #expect(Architecture.universal.isCompatibleWithHost == false)
        #else
        #expect(Architecture.universal.isCompatibleWithHost == true)
        #endif
    }
    
    @Test
    func hostArchitecture_isCompatibleWithHost() {
        #expect(Architecture.host.isCompatibleWithHost == true)
    }
    
    // MARK: - Binary Detection Tests
    
    @Test
    func detectArchitecture_validMachOBinary() throws {
        let architectureValidatorFileManager = ArchitectureValidatorFileManagerMock(fileManager: .default)
        let architectureValidator = ArchitectureValidator(fileManager: architectureValidatorFileManager)
        
        let fixture = Fixture(filename: "MockRelease", type: "zip")
        let bundle = Bundle.module
        let path = try #require(bundle.path(forResource: fixture.filename, ofType: fixture.type))
        
        let destination = fileManager.temporaryDirectory.path() + "/tmp_ArchTest-\(UUID().uuidString)/"
        defer { try? fileManager.removeItem(atPath: destination) }
        
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/env")
        process.arguments = ["unzip", "-q", "-o", path, "-d", destination]
        try process.run()
        process.waitUntilExit()
        
        // Find the binary in the extracted archive
        let binaryFinderFileManager = BinaryFinderFileManagerMock(fileManager: .default)
        let binaryFinder = BinaryFinder(fileManager: binaryFinderFileManager)
        let binaryPath = try binaryFinder.findBinary(atPath: destination)
        let fullBinaryPath = destination + binaryPath
        
        let architecture = try architectureValidator.detectArchitecture(at: fullBinaryPath)
        
        // The binary should be detected as a valid architecture
        #expect(architecture == .arm64 || architecture == .x86_64 || architecture == .universal)
    }
    
    @Test
    func validate_compatibleBinary_succeeds() throws {
        let architectureValidatorFileManager = ArchitectureValidatorFileManagerMock(fileManager: .default)
        let architectureValidator = ArchitectureValidator(fileManager: architectureValidatorFileManager)
        
        #if os(Linux)
        let fixture: Fixture
        switch Architecture.host {
        case .arm64:
            fixture = Fixture(filename: "MockELF_ARM64_Release", type: "zip")
        case .x86_64:
            fixture = Fixture(filename: "MockELF_X86_64_Release", type: "zip")
        default:
            throw ArchitectureValidatorTestsError.unknownHostArchitecture
        }
        #else
        let fixture = Fixture(filename: "MockRelease", type: "zip")
        #endif
        let bundle = Bundle.module
        let path = try #require(bundle.path(forResource: fixture.filename, ofType: fixture.type))
        
        let destination = fileManager.temporaryDirectory.path() + "/tmp_ArchTest-\(UUID().uuidString)/"
        defer { try? fileManager.removeItem(atPath: destination) }
        
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/env")
        process.arguments = ["unzip", "-q", "-o", path, "-d", destination]
        try process.run()
        process.waitUntilExit()
        
        // Find the binary in the extracted archive
        let binaryFinderFileManager = BinaryFinderFileManagerMock(fileManager: .default)
        let binaryFinder = BinaryFinder(fileManager: binaryFinderFileManager)
        let binaryPath = try binaryFinder.findBinary(atPath: destination)
        let fullBinaryPath = destination + binaryPath
        
        // Should not throw if binary is compatible (test binaries should be universal or match host)
        try architectureValidator.validate(binaryPath: fullBinaryPath)
    }
    
    @Test
    func detectArchitecture_nonExistentFile_throws() throws {
        let architectureValidatorFileManager = ArchitectureValidatorFileManagerMock(fileManager: .default)
        let architectureValidator = ArchitectureValidator(fileManager: architectureValidatorFileManager)
        
        let nonExistentPath = "/nonexistent/path/to/binary"
        
        #expect(throws: ArchitectureValidator.ArchitectureValidatorError.unableToReadBinary(path: nonExistentPath)) {
            try architectureValidator.detectArchitecture(at: nonExistentPath)
        }
    }
    
    @Test
    func validate_nonExistentFile_throws() throws {
        let architectureValidatorFileManager = ArchitectureValidatorFileManagerMock(fileManager: .default)
        let architectureValidator = ArchitectureValidator(fileManager: architectureValidatorFileManager)
        
        let nonExistentPath = "/nonexistent/path/to/binary"
        
        #expect(throws: ArchitectureValidator.ArchitectureValidatorError.unableToReadBinary(path: nonExistentPath)) {
            try architectureValidator.validate(binaryPath: nonExistentPath)
        }
    }
    
    @Test
    func detectArchitecture_nonMachOFile_throwsUnknownArchitecture() throws {
        let architectureValidatorFileManager = ArchitectureValidatorFileManagerMock(fileManager: .default)
        let architectureValidator = ArchitectureValidator(fileManager: architectureValidatorFileManager)
        
        // Use a non-Mach-O file (the zip archive itself)
        let fixture = Fixture(filename: "MockRelease", type: "zip")
        let bundle = Bundle.module
        let path = try #require(bundle.path(forResource: fixture.filename, ofType: fixture.type))
        
        #expect(throws: ArchitectureValidator.ArchitectureValidatorError.unknownArchitecture(path: path)) {
            try architectureValidator.detectArchitecture(at: path)
        }
    }
    
    // MARK: - ELF Binary Tests
    
    @Test
    func detectArchitecture_syntheticELF_x86_64() throws {
        let architectureValidatorFileManager = SyntheticBinaryFileManagerMock(binaryFormat: .elfX86_64)
        let architectureValidator = ArchitectureValidator(fileManager: architectureValidatorFileManager)
        
        let architecture = try architectureValidator.detectArchitecture(at: "/fake/path")
        #expect(architecture == .x86_64)
    }
    
    @Test
    func detectArchitecture_syntheticELF_aarch64() throws {
        let architectureValidatorFileManager = SyntheticBinaryFileManagerMock(binaryFormat: .elfAarch64)
        let architectureValidator = ArchitectureValidator(fileManager: architectureValidatorFileManager)
        
        let architecture = try architectureValidator.detectArchitecture(at: "/fake/path")
        #expect(architecture == .arm64)
    }
    
    @Test
    func detectArchitecture_syntheticELF_unknownMachine_throws() throws {
        let architectureValidatorFileManager = SyntheticBinaryFileManagerMock(binaryFormat: .elfUnknown)
        let architectureValidator = ArchitectureValidator(fileManager: architectureValidatorFileManager)
        
        #expect(throws: ArchitectureValidator.ArchitectureValidatorError.unknownArchitecture(path: "/fake/path")) {
            try architectureValidator.detectArchitecture(at: "/fake/path")
        }
    }
    
    @Test
    func validate_compatibleELF_succeeds() throws {
        // Create a synthetic ELF matching the host architecture
        let format: SyntheticBinaryFileManagerMock.BinaryFormat = {
            #if arch(arm64)
            return .elfAarch64
            #else
            return .elfX86_64
            #endif
        }()
        let architectureValidatorFileManager = SyntheticBinaryFileManagerMock(binaryFormat: format)
        let architectureValidator = ArchitectureValidator(fileManager: architectureValidatorFileManager)
        
        try architectureValidator.validate(binaryPath: "/fake/path/binary")
    }
    
    @Test
    func validate_incompatibleELF_throws() throws {
        let incompatibleFormat: SyntheticBinaryFileManagerMock.BinaryFormat =
            Architecture.host == .arm64 ? .elfX86_64 : .elfAarch64
        let expectedArch: Architecture = Architecture.host == .arm64 ? .x86_64 : .arm64
        let architectureValidatorFileManager = SyntheticBinaryFileManagerMock(binaryFormat: incompatibleFormat)
        let architectureValidator = ArchitectureValidator(fileManager: architectureValidatorFileManager)
        
        #expect(throws: ArchitectureValidator.ArchitectureValidatorError.incompatibleArchitecture(
            binary: "binary",
            binaryArch: expectedArch,
            hostArch: Architecture.host
        )) {
            try architectureValidator.validate(binaryPath: "/fake/path/binary")
        }
    }
    
    // MARK: - Synthetic Binary Tests
    
    @Test
    func detectArchitecture_syntheticArm64Binary() throws {
        let architectureValidatorFileManager = SyntheticBinaryFileManagerMock(architecture: .arm64)
        let architectureValidator = ArchitectureValidator(fileManager: architectureValidatorFileManager)
        
        let architecture = try architectureValidator.detectArchitecture(at: "/fake/path")
        #expect(architecture == .arm64)
    }
    
    @Test
    func detectArchitecture_syntheticX86_64Binary() throws {
        let architectureValidatorFileManager = SyntheticBinaryFileManagerMock(architecture: .x86_64)
        let architectureValidator = ArchitectureValidator(fileManager: architectureValidatorFileManager)
        
        let architecture = try architectureValidator.detectArchitecture(at: "/fake/path")
        #expect(architecture == .x86_64)
    }
    
    @Test
    func detectArchitecture_syntheticUniversalBinary() throws {
        let architectureValidatorFileManager = SyntheticBinaryFileManagerMock(architecture: .universal)
        let architectureValidator = ArchitectureValidator(fileManager: architectureValidatorFileManager)
        
        let architecture = try architectureValidator.detectArchitecture(at: "/fake/path")
        #expect(architecture == .universal)
    }
    
    @Test
    func validate_incompatibleArchitecture_throws() throws {
        // Create a mock that returns the opposite architecture of the host
        let incompatibleArch: Architecture = Architecture.host == .arm64 ? .x86_64 : .arm64
        let architectureValidatorFileManager = SyntheticBinaryFileManagerMock(architecture: incompatibleArch)
        let architectureValidator = ArchitectureValidator(fileManager: architectureValidatorFileManager)
        
        #expect(throws: ArchitectureValidator.ArchitectureValidatorError.incompatibleArchitecture(
            binary: "binary",
            binaryArch: incompatibleArch,
            hostArch: Architecture.host
        )) {
            try architectureValidator.validate(binaryPath: "/fake/path/binary")
        }
    }
}

// MARK: - Synthetic Binary File Manager Mock

/// A mock file manager that returns synthetic Mach-O or ELF binary data for testing architecture detection.
private struct SyntheticBinaryFileManagerMock: ArchitectureValidatorFileManaging {
    
    enum BinaryFormat {
        case machOArm64
        case machOX86_64
        case machOUniversal
        case elfX86_64
        case elfAarch64
        case elfUnknown
    }
    
    private let binaryFormat: BinaryFormat
    
    /// Legacy convenience initialiser used by existing Mach-O tests.
    init(architecture: Architecture) {
        switch architecture {
        case .arm64:     self.binaryFormat = .machOArm64
        case .x86_64:    self.binaryFormat = .machOX86_64
        case .universal: self.binaryFormat = .machOUniversal
        }
    }
    
    init(binaryFormat: BinaryFormat) {
        self.binaryFormat = binaryFormat
    }
    
    func contents(atPath path: String) -> Data? {
        switch binaryFormat {
        case .machOArm64:
            return createMachO64Header(cpuType: 0x0100000C)
        case .machOX86_64:
            return createMachO64Header(cpuType: 0x01000007)
        case .machOUniversal:
            return createFatHeader(cpuTypes: [0x0100000C, 0x01000007])
        case .elfX86_64:
            return createELFHeader(eMachine: 0x3E)   // EM_X86_64
        case .elfAarch64:
            return createELFHeader(eMachine: 0xB7)   // EM_AARCH64
        case .elfUnknown:
            return createELFHeader(eMachine: 0xFF)   // bogus
        }
    }
    
    func fileExists(atPath path: String) -> Bool {
        true
    }
    
    // MARK: - Private
    
    private func createMachO64Header(cpuType: UInt32) -> Data {
        var data = Data()
        // MH_MAGIC_64 (little-endian)
        var magic: UInt32 = 0xFEEDFACF
        data.append(Data(bytes: &magic, count: 4))
        // CPU type
        var cpu = cpuType
        data.append(Data(bytes: &cpu, count: 4))
        // Padding to ensure enough data
        data.append(Data(repeating: 0, count: 24))
        return data
    }
    
    private func createFatHeader(cpuTypes: [UInt32]) -> Data {
        var data = Data()
        // FAT_MAGIC (big-endian)
        var magic: UInt32 = UInt32(0xCAFEBABE).bigEndian
        data.append(Data(bytes: &magic, count: 4))
        // Number of architectures (big-endian)
        var nfatArch: UInt32 = UInt32(cpuTypes.count).bigEndian
        data.append(Data(bytes: &nfatArch, count: 4))
        // Fat arch entries (each 20 bytes for 32-bit fat)
        for cpuType in cpuTypes {
            // CPU type (big-endian)
            var cpu = cpuType.bigEndian
            data.append(Data(bytes: &cpu, count: 4))
            // CPU subtype (big-endian)
            var subtype: UInt32 = 0
            data.append(Data(bytes: &subtype, count: 4))
            // Offset (big-endian)
            var offset: UInt32 = 0
            data.append(Data(bytes: &offset, count: 4))
            // Size (big-endian)
            var size: UInt32 = 0
            data.append(Data(bytes: &size, count: 4))
            // Align (big-endian)
            var align: UInt32 = 0
            data.append(Data(bytes: &align, count: 4))
        }
        return data
    }
    
    /// Creates a minimal ELF header with the given `e_machine` value (little-endian).
    private func createELFHeader(eMachine: UInt16) -> Data {
        var data = Data()
        // ELF magic (4 bytes)
        data.append(contentsOf: [0x7F, 0x45, 0x4C, 0x46])
        // EI_CLASS: 64-bit
        data.append(2)
        // EI_DATA: little-endian
        data.append(1)
        // EI_VERSION
        data.append(1)
        // EI_OSABI + padding (9 bytes to reach offset 16)
        data.append(Data(repeating: 0, count: 9))
        // e_type (2 bytes): ET_EXEC = 2
        var eType: UInt16 = 2
        data.append(Data(bytes: &eType, count: 2))
        // e_machine (2 bytes) — at offset 18
        var machine = eMachine
        data.append(Data(bytes: &machine, count: 2))
        // Padding to ensure enough data
        data.append(Data(repeating: 0, count: 12))
        return data
    }
}
