//  BinaryFinderTests.swift

import Foundation
import Testing
@testable import LucaCore

struct BinaryFinderTests {
    
    private let fileManager = FileManager.default
    
    @Test
    func findBinary_valid_MachO_Release() throws {
        let binaryFinderFileManager = BinaryFinderFileManagerMock(fileManager: .default)
        let binaryFinder = BinaryFinder(fileManager: binaryFinderFileManager)
        
        let fixture = Fixture(filename: "MockMachO_Universal_Release", type: "zip")
        let bundle = Bundle.module
        let path = try #require(bundle.path(forResource: fixture.filename, ofType: fixture.type))

        let destination = fileManager.temporaryDirectory.path() + "/tmp_MockMachORelease-\(UUID().uuidString)/"

        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/env")
        process.arguments = ["unzip", "-q", "-o", path, "-d", destination]
        try process.run()
        process.waitUntilExit()

        let binaryPath = try binaryFinder.findBinary(atPath: destination)

        #expect(binaryPath == "bin/MockMachOTool")
    }
    
    @Test
    func findBinary_validELFRelease() throws {
        let binaryFinderFileManager = BinaryFinderFileManagerMock(fileManager: .default)
        let binaryFinder = BinaryFinder(fileManager: binaryFinderFileManager)
        
        let fixture = Fixture(filename: "MockELF_ARM64_Release", type: "zip")
        let bundle = Bundle.module
        let path = try #require(bundle.path(forResource: fixture.filename, ofType: fixture.type))
        
        let destination = fileManager.temporaryDirectory.path() + "/tmp_MockELF_ARM64_Release-\(UUID().uuidString)/"
        
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/env")
        process.arguments = ["unzip", "-q", "-o", path, "-d", destination]
        try process.run()
        process.waitUntilExit()

        let binaryPath = try binaryFinder.findBinary(atPath: destination)

        #expect(binaryPath == "bin/MockELFTool")
    }
    
    @Test
    func findBinary_invalidRelease() throws {
        let binaryFinderFileManager = BinaryFinderFileManagerMock(fileManager: .default)
        let binaryFinder = BinaryFinder(fileManager: binaryFinderFileManager)
        
        let fixture = Fixture(filename: "MockContent", type: "zip")
        let bundle = Bundle.module
        let path = try #require(bundle.path(forResource: fixture.filename, ofType: fixture.type))

        let destination = fileManager.temporaryDirectory.path() + "/tmp_MockRelease-\(UUID().uuidString)/"

        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/env")
        process.arguments = ["unzip", "-q", "-o", path, "-d", destination]
        try process.run()
        process.waitUntilExit()

        #expect(throws: BinaryFinder.BinaryFinderError.missingBinaryFile(location: destination)) {
            try binaryFinder.findBinary(atPath: destination)
        }
    }
}
