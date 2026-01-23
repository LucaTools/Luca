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
        let installer = Installer(fileManager: fileManager, ignoreArchitectureCheck: true, printer: PrinterMock())
        
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
        let installer = Installer(fileManager: fileManager, ignoreArchitectureCheck: true, printer: PrinterMock())
        
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
        let installer = Installer(fileManager: fileManager, ignoreArchitectureCheck: true, printer: PrinterMock())
        
        let fixture = Fixture(filename: "Lucafile_invalid", type: "yml")
        let bundle = Bundle.module
        let path = try #require(bundle.path(forResource: fixture.filename, ofType: fixture.type))
        
        await #expect(throws: (any Error).self) {
            try await installer.install(installationType: .spec(specPath: URL(string: path)!))
        }
    }
    
    @Test
    func test_reinstallSpec() async throws {
        let installer = Installer(fileManager: fileManager, ignoreArchitectureCheck: true, printer: PrinterMock())
        
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
        let installer = Installer(fileManager: fileManager, ignoreArchitectureCheck: true, printer: PrinterMock())
        
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
        let installer = Installer(fileManager: fileManager, ignoreArchitectureCheck: true, printer: PrinterMock())
        
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
    
    @Test
    func test_installSpec_unlinksOrphanedTools() async throws {
        let installer = Installer(fileManager: fileManager, ignoreArchitectureCheck: true, printer: PrinterMock())
        
        // First, install the full spec with all tools
        let fullFixture = Fixture(filename: "Lucafile_valid", type: "yml")
        let bundle = Bundle.module
        let fullPath = try #require(bundle.path(forResource: fullFixture.filename, ofType: fullFixture.type))
        let fullSpec = try spec(for: fullFixture)
        
        try await installer.install(installationType: .spec(specPath: URL(string: fullPath)!))
        
        // Verify all tools are installed and linked
        for tool in fullSpec.tools {
            let toolSymLink = fileManager.activeFolder
                .appending(component: tool.expectedBinaryName)
            #expect(fileManager.fileExists(atPath: toolSymLink.path))
        }
        
        // Now install a subset spec (missing PackageGenerator and ToggleGen)
        let subsetFixture = Fixture(filename: "Lucafile_valid_subset", type: "yml")
        let subsetPath = try #require(bundle.path(forResource: subsetFixture.filename, ofType: subsetFixture.type))
        let subsetSpec = try spec(for: subsetFixture)
        
        try await installer.install(installationType: .spec(specPath: URL(string: subsetPath)!))
        
        // Verify tools in subset spec are still linked
        for tool in subsetSpec.tools {
            let toolSymLink = fileManager.activeFolder
                .appending(component: tool.expectedBinaryName)
            #expect(fileManager.fileExists(atPath: toolSymLink.path))
        }
        
        // Verify tools NOT in subset spec have been unlinked (by tool name, not binary name)
        let subsetToolNames = Set(subsetSpec.tools.map(\.name))
        let removedTools = fullSpec.tools.filter { !subsetToolNames.contains($0.name) }
        
        for tool in removedTools {
            let toolSymLink = fileManager.activeFolder
                .appending(component: tool.expectedBinaryName)
            #expect(!fileManager.fileExists(atPath: toolSymLink.path))
        }
    }
    
    @Test
    func test_installIndividual_doesNotUnlinkExistingTools() async throws {
        let installer = Installer(fileManager: fileManager, ignoreArchitectureCheck: true, printer: PrinterMock())
        
        // First, install a spec with multiple tools
        let fullFixture = Fixture(filename: "Lucafile_valid", type: "yml")
        let bundle = Bundle.module
        let fullPath = try #require(bundle.path(forResource: fullFixture.filename, ofType: fullFixture.type))
        let fullSpec = try spec(for: fullFixture)
        
        try await installer.install(installationType: .spec(specPath: URL(string: fullPath)!))
        
        // Install an individual tool (not from the spec)
        let swiftLintFixture = Fixture(filename: "Lucafile_LowVersion", type: "yml")
        let swiftLintSpec = try spec(for: swiftLintFixture)
        let swiftLintTool = swiftLintSpec.tools.first!
        
        try await installer.install(
            installationType: .individualInline(
                name: swiftLintTool.name,
                version: swiftLintTool.version,
                url: swiftLintTool.url,
                binaryPath: swiftLintTool.binaryPath,
                desiredBinaryName: swiftLintTool.desiredBinaryName,
                checksum: swiftLintTool.checksum,
                algorithm: swiftLintTool.algorithm
            )
        )
        
        // Verify ALL original tools from the full spec are still linked
        // (individual installs should NOT unlink existing tools)
        for tool in fullSpec.tools {
            let toolSymLink = fileManager.activeFolder
                .appending(component: tool.expectedBinaryName)
            #expect(fileManager.fileExists(atPath: toolSymLink.path))
        }
        
        // Verify the new individual tool is also linked
        let swiftLintSymLink = fileManager.activeFolder
            .appending(component: swiftLintTool.expectedBinaryName)
        #expect(fileManager.fileExists(atPath: swiftLintSymLink.path))
    }
    
    @Test
    func test_installSpec_noOrphanedTools() async throws {
        let installer = Installer(fileManager: fileManager, ignoreArchitectureCheck: true, printer: PrinterMock())
        
        // Install a spec
        let fixture = Fixture(filename: "Lucafile_valid", type: "yml")
        let bundle = Bundle.module
        let path = try #require(bundle.path(forResource: fixture.filename, ofType: fixture.type))
        let spec = try spec(for: fixture)
        
        try await installer.install(installationType: .spec(specPath: URL(string: path)!))
        
        // Install the same spec again
        try await installer.install(installationType: .spec(specPath: URL(string: path)!))
        
        // All tools should still be linked (no orphans to unlink)
        for tool in spec.tools {
            let toolSymLink = fileManager.activeFolder
                .appending(component: tool.expectedBinaryName)
            #expect(fileManager.fileExists(atPath: toolSymLink.path))
        }
    }
    
    @Test
    func test_installSpec_doesNotUnlinkToolsWithDifferentBinaryNameCasing() async throws {
        // This test verifies that tools are not incorrectly unlinked when the symlink name
        // differs from the tool name (e.g., "swiftlint" symlink vs "SwiftLint" tool name).
        // The orphan detection should compare by tool name, not binary name.
        
        let installer = Installer(fileManager: fileManager, ignoreArchitectureCheck: true, printer: PrinterMock())
        
        // Install SwiftLint from the spec
        let fixture = Fixture(filename: "Lucafile_LowVersion", type: "yml")
        let bundle = Bundle.module
        let path = try #require(bundle.path(forResource: fixture.filename, ofType: fixture.type))
        
        try await installer.install(installationType: .spec(specPath: URL(string: path)!))
        
        // The symlink is created with the binary name (lowercase "swiftlint") 
        // but the tool name in the spec is "SwiftLint"
        let swiftlintSymLink = fileManager.activeFolder.appending(component: "swiftlint")
        #expect(fileManager.fileExists(atPath: swiftlintSymLink.path))
        
        // Reinstall the same spec - the tool should NOT be unlinked
        // because the comparison should be by tool name ("SwiftLint"), not binary name ("swiftlint")
        try await installer.install(installationType: .spec(specPath: URL(string: path)!))
        
        // Verify the symlink still exists after reinstall
        #expect(fileManager.fileExists(atPath: swiftlintSymLink.path))
    }
    
    @Test
    func test_installSpec_unlinksToolsByName() async throws {
        // This test verifies that orphan detection correctly identifies tools to unlink
        // by comparing tool names (from folder structure) against spec tool names.
        
        let installer = Installer(fileManager: fileManager, ignoreArchitectureCheck: true, printer: PrinterMock())
        
        // First, install a spec with SwiftLint
        let swiftLintFixture = Fixture(filename: "Lucafile_LowVersion", type: "yml")
        let bundle = Bundle.module
        let swiftLintPath = try #require(bundle.path(forResource: swiftLintFixture.filename, ofType: swiftLintFixture.type))
        
        try await installer.install(installationType: .spec(specPath: URL(string: swiftLintPath)!))
        
        let swiftlintSymLink = fileManager.activeFolder.appending(component: "swiftlint")
        #expect(fileManager.fileExists(atPath: swiftlintSymLink.path))
        
        // Now install a different spec that does NOT include SwiftLint
        let differentFixture = Fixture(filename: "Lucafile_valid_subset", type: "yml")
        let differentPath = try #require(bundle.path(forResource: differentFixture.filename, ofType: differentFixture.type))
        
        try await installer.install(installationType: .spec(specPath: URL(string: differentPath)!))
        
        // SwiftLint should be unlinked because it's not in the new spec (by tool name)
        #expect(!fileManager.fileExists(atPath: swiftlintSymLink.path))
        
        // But tools in the new spec should still be linked
        let sourcerySymLink = fileManager.activeFolder.appending(component: "sourcery")
        let firebaseSymLink = fileManager.activeFolder.appending(component: "firebase")
        #expect(fileManager.fileExists(atPath: sourcerySymLink.path))
        #expect(fileManager.fileExists(atPath: firebaseSymLink.path))
    }
    
    private func spec(for fixture: Fixture) throws -> Spec {
        let bundle = Bundle.module
        let path = try #require(bundle.path(forResource: fixture.filename, ofType: fixture.type))
        let data = try Data(contentsOf: URL(fileURLWithPath: path))
        return try YAMLDecoder().decode(Spec.self, from: data)
    }
}
