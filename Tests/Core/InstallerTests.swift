//  InstallerTests.swift

import Foundation
import Testing
import Yams
@testable import LucaCore

struct InstallerTests {

    private let fileManager: FileManaging
    
    init() async throws {
        fileManager = FileManagerWrapperMock()
    }
      
    @Test(arguments: ["Lucafile_valid", "Lucafile_valid_missingBinaryPath"])
    func test_installIndividuals(filename: String) async throws {
        let installer = Installer(fileManager: fileManager)
        
        let fixture = Fixture(filename: filename, type: "yml")
        let bundle = Bundle.module
        let path = try #require(bundle.path(forResource: fixture.filename, ofType: fixture.type))
        let data = try Data(contentsOf: URL(fileURLWithPath: path))
        let spec = try YAMLDecoder().decode(Spec.self, from: data)
        
        for tool in spec.tools {
            let toolPath = fileManager.toolsFolder
                .appending(component: tool.name)
                .appending(components: tool.version)
            let toolSymLink = fileManager.activeFolder
                .appending(component: tool.desiredBinaryName ?? tool.name)

            #expect(!fileManager.fileExists(atPath: toolPath.path))
            #expect(!fileManager.fileExists(atPath: toolSymLink.path))

            try await installer
                .install(
                    installationType: .individualInline(
                        name: tool.name,
                        version: tool.version,
                        url: tool.url,
                        binaryPath: tool.binaryPath,
                        desiredBinaryName: tool.desiredBinaryName,
                        checksum: tool.checksum,
                        algorithm: tool.algorithm
                    )
                )
                                        
            #expect(fileManager.fileExists(atPath: toolPath.path))
            #expect(fileManager.fileExists(atPath: toolSymLink.path))
            
            let binaryFinder = BinaryFinder(fileManager: fileManager)
            let binaryPath = try binaryFinder.findBinary(atPath: toolPath.path)
            
            let expectedToolSymlinkDestination = fileManager.toolsFolder
                .appending(component: tool.name)
                .appending(component: tool.version)
                .appending(component: binaryPath)
            
            let externalToolSymlinkDestination = try fileManager.destinationOfSymbolicLink(atPath: toolSymLink.path)
            
            #expect(externalToolSymlinkDestination == expectedToolSymlinkDestination.path)
        }
    }
    
    @Test(arguments: ["Lucafile_valid", "Lucafile_valid_missingBinaryPath"])
    func test_installSpec(filename: String) async throws {
        let installer = Installer(fileManager: fileManager)
        
        let fixture = Fixture(filename: filename, type: "yml")
        let bundle = Bundle.module
        let path = try #require(bundle.path(forResource: fixture.filename, ofType: fixture.type))
        let data = try Data(contentsOf: URL(fileURLWithPath: path))
        let spec = try YAMLDecoder().decode(Spec.self, from: data)
        
        try await installer.install(installationType: .spec(specPath: URL(string: path)!))
        
        for tool in spec.tools {
            let toolPath = fileManager.toolsFolder
                .appending(component: tool.name)
                .appending(components: tool.version)
            let toolSymLink = fileManager.activeFolder
                .appending(component: tool.desiredBinaryName ?? tool.name)

            #expect(fileManager.fileExists(atPath: toolPath.path))
            #expect(fileManager.fileExists(atPath: toolSymLink.path))
            
            let binaryFinder = BinaryFinder(fileManager: fileManager)
            let binaryPath = try binaryFinder.findBinary(atPath: toolPath.path)
            
            let expectedToolSymlinkDestination = fileManager.toolsFolder
                .appending(component: tool.name)
                .appending(component: tool.version)
                .appending(component: binaryPath)
            
            let externalToolSymlinkDestination = try fileManager.destinationOfSymbolicLink(atPath: toolSymLink.path)
            
            #expect(externalToolSymlinkDestination == expectedToolSymlinkDestination.path)
        }
    }
    
    @Test
    func test_installInvalid() async throws {
        let installer = Installer(fileManager: fileManager)
        
        let fixture = Fixture(filename: "Lucafile_invalid", type: "yml")
        let bundle = Bundle.module
        let path = try #require(bundle.path(forResource: fixture.filename, ofType: fixture.type))
        
        await #expect(throws: (any Error).self) {
            try await installer.install(installationType: .spec(specPath: URL(string: path)!))
        }
    }
    
    @Test
    func test_reinstallSpec() async throws {
        let installer = Installer(fileManager: fileManager)
        
        let fixture = Fixture(filename: "Lucafile_valid", type: "yml")
        let bundle = Bundle.module
        let path = try #require(bundle.path(forResource: fixture.filename, ofType: fixture.type))
        let data = try Data(contentsOf: URL(fileURLWithPath: path))
        let spec = try YAMLDecoder().decode(Spec.self, from: data)
        
        try await installer.install(installationType: .spec(specPath: URL(string: path)!))
        try await installer.install(installationType: .spec(specPath: URL(string: path)!))
        
        for tool in spec.tools {
            let toolPath = fileManager.toolsFolder
                .appending(component: tool.name)
                .appending(components: tool.version)
            let toolSymLink = fileManager.activeFolder
                .appending(component: tool.desiredBinaryName ?? tool.name)

            #expect(fileManager.fileExists(atPath: toolPath.path))
            #expect(fileManager.fileExists(atPath: toolSymLink.path))
            
            let binaryFinder = BinaryFinder(fileManager: fileManager)
            let binaryPath = try binaryFinder.findBinary(atPath: toolPath.path)
            
            let expectedToolSymlinkDestination = fileManager.toolsFolder
                .appending(component: tool.name)
                .appending(component: tool.version)
                .appending(component: binaryPath)
            
            let externalToolSymlinkDestination = try fileManager.destinationOfSymbolicLink(atPath: toolSymLink.path)
            
            #expect(externalToolSymlinkDestination == expectedToolSymlinkDestination.path)
        }
    }
    
    @Test
    func test_installToolUpgradeVersion() async throws {
        let installer = Installer(fileManager: fileManager)
        
        let lowVersionFixture = Fixture(filename: "Lucafile_LowVersion", type: "yml")
        let highVersionFixture = Fixture(filename: "Lucafile_HighVersion", type: "yml")
        let bundle = Bundle.module
        let lowVersionPath = try #require(bundle.path(forResource: lowVersionFixture.filename, ofType: lowVersionFixture.type))
        let highVersionPath = try #require(bundle.path(forResource: highVersionFixture.filename, ofType: highVersionFixture.type))
        
        try await installer.install(installationType: .spec(specPath: URL(string: lowVersionPath)!))
        try await installer.install(installationType: .spec(specPath: URL(string: highVersionPath)!))

        let highVersionSpec = try spec(for: highVersionFixture)
        
        for tool in highVersionSpec.tools {
            let toolPath = fileManager.toolsFolder
                .appending(component: tool.name)
                .appending(components: tool.version)
            
            let binaryFinder = BinaryFinder(fileManager: fileManager)
            let binaryPath = try binaryFinder.findBinary(atPath: toolPath.path)
            
            let higherVersionToolSymlink = fileManager.activeFolder
                .appending(component: tool.name)
            
            let expectedHigherVersionToolSymlinkDestination = fileManager.toolsFolder
                .appending(components: tool.name, tool.version, binaryPath)
            
            let higherVersionToolSymlinkDestination = try fileManager.destinationOfSymbolicLink(atPath: higherVersionToolSymlink.path)
            #expect(higherVersionToolSymlinkDestination == expectedHigherVersionToolSymlinkDestination.path)
        }
    }
    
    @Test
    func test_installToolDowngradeVersion() async throws {
        let installer = Installer(fileManager: fileManager)
        
        let lowVersionFixture = Fixture(filename: "Lucafile_LowVersion", type: "yml")
        let highVersionFixture = Fixture(filename: "Lucafile_HighVersion", type: "yml")
        let bundle = Bundle.module
        let lowVersionPath = try #require(bundle.path(forResource: lowVersionFixture.filename, ofType: lowVersionFixture.type))
        let highVersionPath = try #require(bundle.path(forResource: highVersionFixture.filename, ofType: highVersionFixture.type))
        
        try await installer.install(installationType: .spec(specPath: URL(string: highVersionPath)!))
        try await installer.install(installationType: .spec(specPath: URL(string: lowVersionPath)!))
        
        let lowVersionSpec = try spec(for: lowVersionFixture)
        
        for tool in lowVersionSpec.tools {
            let toolPath = fileManager.toolsFolder
                .appending(component: tool.name)
                .appending(components: tool.version)
            
            let binaryFinder = BinaryFinder(fileManager: fileManager)
            let binaryPath = try binaryFinder.findBinary(atPath: toolPath.path)
            
            let higherVersionToolSymlink = fileManager.activeFolder
                .appending(component: tool.name)
            
            let expectedHigherVersionToolSymlinkDestination = fileManager.toolsFolder
                .appending(components: tool.name, tool.version, binaryPath)
            
            let higherVersionToolSymlinkDestination = try fileManager.destinationOfSymbolicLink(atPath: higherVersionToolSymlink.path)
            #expect(higherVersionToolSymlinkDestination == expectedHigherVersionToolSymlinkDestination.path)
        }
    }
    
    private func spec(for fixture: Fixture) throws -> Spec {
        let bundle = Bundle.module
        let path = try #require(bundle.path(forResource: fixture.filename, ofType: fixture.type))
        let data = try Data(contentsOf: URL(fileURLWithPath: path))
        return try YAMLDecoder().decode(Spec.self, from: data)
    }
}
