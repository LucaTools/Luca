//  ArchitectureValidatorTests.swift

import Foundation
import Testing
@testable import LucaCore

struct ArchitectureValidatorTests {
    
    private let fileManager = FileManager.default
    
    // MARK: - Architecture Model Tests
    
    @Test
    func hostArchitecture_returnsValidArchitecture() {
        let host = Architecture.host
        #expect(host == .arm64 || host == .x86_64)
    }
    
    @Test
    func universalArchitecture_isAlwaysCompatible() {
        #expect(Architecture.universal.isCompatibleWithHost == true)
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
        
        let destination = fileManager.currentDirectoryPath + "/tmp_ArchTest-\(UUID().uuidString)/"
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
        
        let fixture = Fixture(filename: "MockRelease", type: "zip")
        let bundle = Bundle.module
        let path = try #require(bundle.path(forResource: fixture.filename, ofType: fixture.type))
        
        let destination = fileManager.currentDirectoryPath + "/tmp_ArchTest-\(UUID().uuidString)/"
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

/// A mock file manager that returns synthetic Mach-O binary data for testing architecture detection.
private struct SyntheticBinaryFileManagerMock: ArchitectureValidatorFileManaging {
    
    private let architecture: Architecture
    
    init(architecture: Architecture) {
        self.architecture = architecture
    }
    
    func contents(atPath path: String) -> Data? {
        switch architecture {
        case .arm64:
            return createMachO64Header(cpuType: 0x0100000C) // CPU_TYPE_ARM64
        case .x86_64:
            return createMachO64Header(cpuType: 0x01000007) // CPU_TYPE_X86_64
        case .universal:
            return createFatHeader(cpuTypes: [0x0100000C, 0x01000007]) // ARM64 + X86_64
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
}
