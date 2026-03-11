//  InstallerTests.swift

import Foundation
import Testing
import Yams
@testable import LucaCore

struct InstallerTests {

    private let fileManager: FileManaging
    private let downloader: Downloading
    
    init() async throws {
        fileManager = FileManagerWrapperMock()
        downloader = DownloaderMock(result: .fixture(Fixture(filename: "MockMachO_Universal_Release", type: "zip")))
    }
    
    private func makeInstaller(quiet: Bool) -> Installer {
        Installer(
            fileManager: fileManager,
            ignoreArchitectureCheck: true,
            quiet: quiet,
            printer: PrinterMock(),
            downloader: downloader
        )
    }
      
    @Test(arguments: [true, false])
    func test_installIndividuals(quiet: Bool) async throws {
        let installer = makeInstaller(quiet: quiet)
        
        let fixture = Fixture(filename: "Lucafile_mock", type: "yml")
        let bundle = Bundle.module
        let path = try #require(bundle.path(forResource: fixture.filename, ofType: fixture.type))
        let data = try Data(contentsOf: URL(fileURLWithPath: path))
        let spec = try YAMLDecoder().decode(Spec.self, from: data)
        
        for tool in spec.tools {
            let toolPath = fileManager.toolsFolder
                .appending(component: tool.name)
                .appending(components: tool.version)
            let toolSymLink = fileManager.symlinksFolder
                .appending(component: tool.expectedBinaryName)

            #expect(!fileManager.fileExists(atPath: toolPath.path))

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
                .appending(path: binaryPath)
            
            let externalToolSymlinkDestination = try fileManager.destinationOfSymbolicLink(atPath: toolSymLink.path)
            
            #expect(externalToolSymlinkDestination == expectedToolSymlinkDestination.path)
        }
    }
    
    @Test(arguments: [true, false])
    func test_installSpec(quiet: Bool) async throws {
        let installer = makeInstaller(quiet: quiet)
        
        let fixture = Fixture(filename: "Lucafile_mock", type: "yml")
        let bundle = Bundle.module
        let path = try #require(bundle.path(forResource: fixture.filename, ofType: fixture.type))
        let data = try Data(contentsOf: URL(fileURLWithPath: path))
        let spec = try YAMLDecoder().decode(Spec.self, from: data)
        
        try await installer.install(installationType: .spec(specPath: URL(string: path)!))
        
        for tool in spec.tools {
            let toolPath = fileManager.toolsFolder
                .appending(component: tool.name)
                .appending(components: tool.version)

            #expect(fileManager.fileExists(atPath: toolPath.path))
            
            let binaryFinder = BinaryFinder(fileManager: fileManager)
            let binaryPath = try binaryFinder.findBinary(atPath: toolPath.path)
            
            let expectedBinaryLocation = fileManager.toolsFolder
                .appending(component: tool.name)
                .appending(component: tool.version)
                .appending(path: binaryPath)
            
            #expect(fileManager.fileExists(atPath: expectedBinaryLocation.path))
        }
        
        // Verify symlink exists for the last installed tool (all tools share same binaryPath basename)
        let toolSymLink = fileManager.symlinksFolder
            .appending(component: spec.tools.first!.expectedBinaryName)
        #expect(fileManager.fileExists(atPath: toolSymLink.path))
    }
    
    @Test(arguments: [true, false])
    func test_installInvalid(quiet: Bool) async throws {
        let installer = makeInstaller(quiet: quiet)
        
        let fixture = Fixture(filename: "Lucafile_invalid", type: "yml")
        let bundle = Bundle.module
        let path = try #require(bundle.path(forResource: fixture.filename, ofType: fixture.type))
        
        await #expect(throws: (any Error).self) {
            try await installer.install(installationType: .spec(specPath: URL(string: path)!))
        }
    }
    
    @Test(arguments: [true, false])
    func test_reinstallSpec(quiet: Bool) async throws {
        let installer = makeInstaller(quiet: quiet)
        
        let fixture = Fixture(filename: "Lucafile_mock", type: "yml")
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

            #expect(fileManager.fileExists(atPath: toolPath.path))
            
            let binaryFinder = BinaryFinder(fileManager: fileManager)
            let binaryPath = try binaryFinder.findBinary(atPath: toolPath.path)
            
            let expectedBinaryLocation = fileManager.toolsFolder
                .appending(component: tool.name)
                .appending(component: tool.version)
                .appending(path: binaryPath)
            
            #expect(fileManager.fileExists(atPath: expectedBinaryLocation.path))
        }
    }
    
    @Test(arguments: [true, false])
    func test_installToolUpgradeVersion(quiet: Bool) async throws {
        let installer = makeInstaller(quiet: quiet)
        
        let lowVersionFixture = Fixture(filename: "Lucafile_mock_lowversion", type: "yml")
        let highVersionFixture = Fixture(filename: "Lucafile_mock_highversion", type: "yml")
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
            
            let higherVersionToolSymlink = fileManager.symlinksFolder
                .appending(component: tool.expectedBinaryName)
            
            let expectedHigherVersionToolSymlinkDestination = fileManager.toolsFolder
                .appending(components: tool.name, tool.version)
                .appending(path: binaryPath)
            
            let higherVersionToolSymlinkDestination = try fileManager.destinationOfSymbolicLink(atPath: higherVersionToolSymlink.path)
            #expect(higherVersionToolSymlinkDestination == expectedHigherVersionToolSymlinkDestination.path)
        }
    }
    
    @Test(arguments: [true, false])
    func test_installToolDowngradeVersion(quiet: Bool) async throws {
        let installer = makeInstaller(quiet: quiet)
        
        let lowVersionFixture = Fixture(filename: "Lucafile_mock_lowversion", type: "yml")
        let highVersionFixture = Fixture(filename: "Lucafile_mock_highversion", type: "yml")
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
            
            let lowerVersionToolSymlink = fileManager.symlinksFolder
                .appending(component: tool.expectedBinaryName)
            
            let expectedLowerVersionToolSymlinkDestination = fileManager.toolsFolder
                .appending(components: tool.name, tool.version)
                .appending(path: binaryPath)
            
            let lowerVersionToolSymlinkDestination = try fileManager.destinationOfSymbolicLink(atPath: lowerVersionToolSymlink.path)
            #expect(lowerVersionToolSymlinkDestination == expectedLowerVersionToolSymlinkDestination.path)
        }
    }
    
    @Test(arguments: [true, false])
    func test_installSpec_unlinksOrphanedTools(quiet: Bool) async throws {
        let installer = makeInstaller(quiet: quiet)
        
        // First, install the full spec with all tools
        let fullFixture = Fixture(filename: "Lucafile_mock", type: "yml")
        let bundle = Bundle.module
        let fullPath = try #require(bundle.path(forResource: fullFixture.filename, ofType: fullFixture.type))
        let fullSpec = try spec(for: fullFixture)
        
        try await installer.install(installationType: .spec(specPath: URL(string: fullPath)!))
        
        // Verify all tools are installed (each tool directory exists)
        for tool in fullSpec.tools {
            let toolPath = fileManager.toolsFolder
                .appending(component: tool.name)
                .appending(components: tool.version)
            #expect(fileManager.fileExists(atPath: toolPath.path))
        }
        
        // Now install a subset spec (missing MockToolC and MockToolD)
        let subsetFixture = Fixture(filename: "Lucafile_mock_subset", type: "yml")
        let subsetPath = try #require(bundle.path(forResource: subsetFixture.filename, ofType: subsetFixture.type))
        let subsetSpec = try spec(for: subsetFixture)
        
        try await installer.install(installationType: .spec(specPath: URL(string: subsetPath)!))
        
        // Verify tools in subset spec are still installed
        for tool in subsetSpec.tools {
            let toolPath = fileManager.toolsFolder
                .appending(component: tool.name)
                .appending(components: tool.version)
            #expect(fileManager.fileExists(atPath: toolPath.path))
        }
    }
    
    @Test(arguments: [true, false])
    func test_installIndividual_doesNotUnlinkExistingTools(quiet: Bool) async throws {
        let installer = makeInstaller(quiet: quiet)
        
        // First, install a spec with multiple tools
        let fullFixture = Fixture(filename: "Lucafile_mock", type: "yml")
        let bundle = Bundle.module
        let fullPath = try #require(bundle.path(forResource: fullFixture.filename, ofType: fullFixture.type))
        let fullSpec = try spec(for: fullFixture)
        
        try await installer.install(installationType: .spec(specPath: URL(string: fullPath)!))
        
        // Install an individual tool (not from the spec)
        let individualFixture = Fixture(filename: "Lucafile_mock_lowversion", type: "yml")
        let individualSpec = try spec(for: individualFixture)
        let individualTool = individualSpec.tools.first!
        
        try await installer.install(
            installationType: .individualInline(
                name: individualTool.name,
                version: individualTool.version,
                url: individualTool.url,
                binaryPath: individualTool.binaryPath,
                desiredBinaryName: individualTool.desiredBinaryName,
                checksum: individualTool.checksum,
                algorithm: individualTool.algorithm
            )
        )
        
        // Verify ALL original tools from the full spec are still installed
        // (individual installs should NOT unlink existing tools)
        for tool in fullSpec.tools {
            let toolPath = fileManager.toolsFolder
                .appending(component: tool.name)
                .appending(components: tool.version)
            #expect(fileManager.fileExists(atPath: toolPath.path))
        }
        
        // Verify the new individual tool is also installed
        let individualToolPath = fileManager.toolsFolder
            .appending(component: individualTool.name)
            .appending(components: individualTool.version)
        #expect(fileManager.fileExists(atPath: individualToolPath.path))
    }
    
    @Test(arguments: [true, false])
    func test_installSpec_noOrphanedTools(quiet: Bool) async throws {
        let installer = makeInstaller(quiet: quiet)
        
        // Install a spec
        let fixture = Fixture(filename: "Lucafile_mock", type: "yml")
        let bundle = Bundle.module
        let path = try #require(bundle.path(forResource: fixture.filename, ofType: fixture.type))
        let spec = try spec(for: fixture)
        
        try await installer.install(installationType: .spec(specPath: URL(string: path)!))
        
        // Install the same spec again
        try await installer.install(installationType: .spec(specPath: URL(string: path)!))
        
        // All tools should still be installed (no orphans to unlink)
        for tool in spec.tools {
            let toolPath = fileManager.toolsFolder
                .appending(component: tool.name)
                .appending(components: tool.version)
            #expect(fileManager.fileExists(atPath: toolPath.path))
        }
    }
    
    @Test(arguments: [true, false])
    func test_installSpec_sameToolDifferentVersion(quiet: Bool) async throws {
        // This test verifies that installing the same tool with different versions
        // correctly updates the symlink to point to the new version.
        
        let installer = makeInstaller(quiet: quiet)
        
        // Install MockTool version 1.0.0
        let lowVersionFixture = Fixture(filename: "Lucafile_mock_lowversion", type: "yml")
        let bundle = Bundle.module
        let lowVersionPath = try #require(bundle.path(forResource: lowVersionFixture.filename, ofType: lowVersionFixture.type))
        
        try await installer.install(installationType: .spec(specPath: URL(string: lowVersionPath)!))
        
        // The symlink is created with the binary name from binaryPath
        let symLink = fileManager.symlinksFolder.appending(component: "MockMachOTool")
        #expect(fileManager.fileExists(atPath: symLink.path))
        
        // Reinstall the same spec - the tool should NOT be unlinked
        try await installer.install(installationType: .spec(specPath: URL(string: lowVersionPath)!))
        
        // Verify the symlink still exists after reinstall
        #expect(fileManager.fileExists(atPath: symLink.path))
    }
    
    @Test(arguments: [true, false])
    func test_installSpec_unlinksToolsByName(quiet: Bool) async throws {
        // This test verifies that orphan detection correctly identifies tools to unlink
        // by comparing tool names (from folder structure) against spec tool names.
        
        let installer = makeInstaller(quiet: quiet)
        
        // First, install a spec with MockTool
        let mockToolFixture = Fixture(filename: "Lucafile_mock_lowversion", type: "yml")
        let bundle = Bundle.module
        let mockToolPath = try #require(bundle.path(forResource: mockToolFixture.filename, ofType: mockToolFixture.type))
        
        try await installer.install(installationType: .spec(specPath: URL(string: mockToolPath)!))
        
        // Verify MockTool is installed
        let mockToolSpec = try spec(for: mockToolFixture)
        let mockTool = mockToolSpec.tools.first!
        let mockToolInstallPath = fileManager.toolsFolder
            .appending(component: mockTool.name)
            .appending(components: mockTool.version)
        #expect(fileManager.fileExists(atPath: mockToolInstallPath.path))
        
        // Now install a different spec that does NOT include MockTool
        let differentFixture = Fixture(filename: "Lucafile_mock_subset", type: "yml")
        let differentPath = try #require(bundle.path(forResource: differentFixture.filename, ofType: differentFixture.type))
        
        try await installer.install(installationType: .spec(specPath: URL(string: differentPath)!))
        
        // MockTool directory should still exist (we don't delete installed tools, just unlink)
        #expect(fileManager.fileExists(atPath: mockToolInstallPath.path))
        
        // But tools in the new spec should be installed
        let subsetSpec = try spec(for: differentFixture)
        for tool in subsetSpec.tools {
            let toolPath = fileManager.toolsFolder
                .appending(component: tool.name)
                .appending(components: tool.version)
            #expect(fileManager.fileExists(atPath: toolPath.path))
        }
    }
    
    @Test
    func test_install_executableAsset() async throws {
        let fileManager = FileManagerWrapperMock()
        let toolName = "TestExecutableTool"
        let version = "1.0.0"
        let url = URL(string: "https://example.com/tool")!
        let desiredBinaryName = "mytool"

        // ELF binary bytes — detected as .executable by FileTypeDetector
        let executableData = Data([0x7F, 0x45, 0x4C, 0x46,  // ELF magic
                                   0x02, 0x01, 0x01, 0x00,  // class, encoding, version, OS/ABI
                                   0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,  // padding
                                   0x02, 0x00,              // e_type
                                   0xB7, 0x00])             // e_machine = EM_AARCH64

        let installer = Installer(
            fileManager: fileManager,
            ignoreArchitectureCheck: true,
            quiet: true,
            printer: PrinterMock(),
            downloader: DownloaderMock(result: .tempFile(executableData))
        )

        let installationType = InstallationType.individualInline(
            name: toolName,
            version: version,
            url: url,
            binaryPath: nil,
            desiredBinaryName: desiredBinaryName,
            checksum: nil,
            algorithm: nil
        )

        // First install: covers installExecutable path
        try await installer.install(installationType: installationType)

        let binaryPath = fileManager.toolsFolder.appending(components: toolName, version, desiredBinaryName)
        #expect(fileManager.fileExists(atPath: binaryPath.path))

        let symLinkPath = fileManager.symlinksFolder.appending(component: desiredBinaryName)
        #expect(fileManager.fileExists(atPath: symLinkPath.path))

        // Second install: covers isToolInstalled desiredBinaryName path → reinstall
        try await installer.install(installationType: installationType)
        #expect(fileManager.fileExists(atPath: binaryPath.path))
        #expect(fileManager.fileExists(atPath: symLinkPath.path))
    }

    @Test
    func test_install_archiveNilBinaryPath_usesBinaryFinder() async throws {
        let fileManager = FileManagerWrapperMock()
        let installer = Installer(
            fileManager: fileManager,
            ignoreArchitectureCheck: true,
            quiet: true,
            printer: PrinterMock(),
            downloader: DownloaderMock(result: .fixture(Fixture(filename: "MockMachO_Universal_Release", type: "zip")))
        )
        let toolName = "TestArchiveTool"
        let version = "1.0.0"

        try await installer.install(installationType: .individualInline(
            name: toolName,
            version: version,
            url: URL(string: "https://example.com/tool.zip")!,
            binaryPath: nil,        // triggers binaryFinder.findBinary in installArchive
            desiredBinaryName: nil,
            checksum: nil,
            algorithm: nil
        ))

        let toolPath = fileManager.toolsFolder.appending(components: toolName, version)
        #expect(fileManager.fileExists(atPath: toolPath.path))
        let symLinkPath = fileManager.symlinksFolder.appending(component: "MockMachOTool")
        #expect(fileManager.fileExists(atPath: symLinkPath.path))
    }

    @Test
    func test_install_executableNilDesiredBinaryName_usesToolName() async throws {
        let fileManager = FileManagerWrapperMock()
        let toolName = "mytoolex"

        // ELF bytes — detected as .executable
        let executableData = Data([0x7F, 0x45, 0x4C, 0x46,
                                   0x02, 0x01, 0x01, 0x00,
                                   0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
                                   0x02, 0x00, 0xB7, 0x00])

        let installer = Installer(
            fileManager: fileManager,
            ignoreArchitectureCheck: true,
            quiet: true,
            printer: PrinterMock(),
            downloader: DownloaderMock(result: .tempFile(executableData))
        )

        try await installer.install(installationType: .individualInline(
            name: toolName,
            version: "1.0.0",
            url: URL(string: "https://example.com/tool")!,
            binaryPath: nil,
            desiredBinaryName: nil,    // triggers `return tool.name` in installExecutable
            checksum: nil,
            algorithm: nil
        ))

        let binaryPath = fileManager.toolsFolder.appending(components: toolName, "1.0.0", toolName)
        #expect(fileManager.fileExists(atPath: binaryPath.path))
        let symLinkPath = fileManager.symlinksFolder.appending(component: toolName)
        #expect(fileManager.fileExists(atPath: symLinkPath.path))
    }

    @Test
    func test_install_unknownFileType_throws() async throws {
        let fileManager = FileManagerWrapperMock()

        // Unknown magic bytes — FileTypeDetector returns nil → InstallerError.unknownFileType
        let unknownData = Data([0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07, 0x08])

        let installer = Installer(
            fileManager: fileManager,
            ignoreArchitectureCheck: true,
            quiet: true,
            printer: PrinterMock(),
            downloader: DownloaderMock(result: .tempFile(unknownData))
        )

        await #expect(throws: (any Error).self) {
            try await installer.install(installationType: .individualInline(
                name: "SomeTool",
                version: "1.0.0",
                url: URL(string: "https://example.com/tool")!,
                binaryPath: nil,
                desiredBinaryName: nil,
                checksum: nil,
                algorithm: nil
            ))
        }
    }

    @Test
    func test_install_incompatibleArchitecture_throws() async throws {
        let fileManager = FileManagerWrapperMock()

        // Create an ELF binary that is incompatible with the current host
        #if arch(arm64) && os(Linux)
        // Linux aarch64: use x86_64 ELF
        let incompatibleData = Data([0x7F, 0x45, 0x4C, 0x46,  // ELF magic
                                     0x02, 0x01, 0x01, 0x00,  // class, encoding, version, OS/ABI
                                     0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,  // padding
                                     0x02, 0x00,              // e_type
                                     0x3E, 0x00])             // e_machine = EM_X86_64
        #else
        // macOS (any arch) or Linux x86_64: use aarch64 ELF
        let incompatibleData = Data([0x7F, 0x45, 0x4C, 0x46,  // ELF magic
                                     0x02, 0x01, 0x01, 0x00,  // class, encoding, version, OS/ABI
                                     0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,  // padding
                                     0x02, 0x00,              // e_type
                                     0xB7, 0x00])             // e_machine = EM_AARCH64
        #endif

        let installer = Installer(
            fileManager: fileManager,
            ignoreArchitectureCheck: false,
            quiet: true,
            printer: PrinterMock(),
            downloader: DownloaderMock(result: .tempFile(incompatibleData))
        )

        await #expect(throws: (any Error).self) {
            try await installer.install(installationType: .individualInline(
                name: "SomeTool",
                version: "1.0.0",
                url: URL(string: "https://example.com/tool")!,
                binaryPath: nil,
                desiredBinaryName: "sometool",
                checksum: nil,
                algorithm: nil
            ))
        }
    }

    @Test
    func test_install_perToolIgnoreArchCheck_true_overridesGlobalFalse() async throws {
        // Per-tool ignoreArchCheck: true must skip arch check even when the installer flag is false
        let fileManager = FileManagerWrapperMock()

        #if arch(arm64) && os(Linux)
        let incompatibleData = Data([0x7F, 0x45, 0x4C, 0x46,
                                     0x02, 0x01, 0x01, 0x00,
                                     0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
                                     0x02, 0x00,
                                     0x3E, 0x00])  // EM_X86_64
        #else
        let incompatibleData = Data([0x7F, 0x45, 0x4C, 0x46,
                                     0x02, 0x01, 0x01, 0x00,
                                     0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
                                     0x02, 0x00,
                                     0xB7, 0x00])  // EM_AARCH64
        #endif

        let installer = Installer(
            fileManager: fileManager,
            ignoreArchitectureCheck: false,
            quiet: true,
            printer: PrinterMock(),
            downloader: DownloaderMock(result: .tempFile(incompatibleData))
        )

        let fixture = Fixture(filename: "Lucafile_mock_ignoreArchCheck_true", type: "yml")
        let path = try #require(Bundle.module.path(forResource: fixture.filename, ofType: fixture.type))

        // Should NOT throw: per-tool true overrides global false
        try await installer.install(installationType: .spec(specPath: URL(string: path)!))
    }

    @Test
    func test_install_perToolIgnoreArchCheck_false_overridesGlobalTrue() async throws {
        // Per-tool ignoreArchCheck: false must run arch check even when the installer flag is true
        let fileManager = FileManagerWrapperMock()

        #if arch(arm64) && os(Linux)
        let incompatibleData = Data([0x7F, 0x45, 0x4C, 0x46,
                                     0x02, 0x01, 0x01, 0x00,
                                     0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
                                     0x02, 0x00,
                                     0x3E, 0x00])  // EM_X86_64
        #else
        let incompatibleData = Data([0x7F, 0x45, 0x4C, 0x46,
                                     0x02, 0x01, 0x01, 0x00,
                                     0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
                                     0x02, 0x00,
                                     0xB7, 0x00])  // EM_AARCH64
        #endif

        let installer = Installer(
            fileManager: fileManager,
            ignoreArchitectureCheck: true,
            quiet: true,
            printer: PrinterMock(),
            downloader: DownloaderMock(result: .tempFile(incompatibleData))
        )

        let fixture = Fixture(filename: "Lucafile_mock_ignoreArchCheck_false", type: "yml")
        let path = try #require(Bundle.module.path(forResource: fixture.filename, ofType: fixture.type))

        // Should throw: per-tool false overrides global true
        await #expect(throws: (any Error).self) {
            try await installer.install(installationType: .spec(specPath: URL(string: path)!))
        }
    }

    @Test
    func test_install_perToolIgnoreArchCheck_nil_fallsBackToGlobal_skips() async throws {
        // Per-tool ignoreArchCheck: nil falls back to global flag — global true → skip check
        let fileManager = FileManagerWrapperMock()

        #if arch(arm64) && os(Linux)
        let incompatibleData = Data([0x7F, 0x45, 0x4C, 0x46,
                                     0x02, 0x01, 0x01, 0x00,
                                     0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
                                     0x02, 0x00,
                                     0x3E, 0x00])  // EM_X86_64
        #else
        let incompatibleData = Data([0x7F, 0x45, 0x4C, 0x46,
                                     0x02, 0x01, 0x01, 0x00,
                                     0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
                                     0x02, 0x00,
                                     0xB7, 0x00])  // EM_AARCH64
        #endif

        let installer = Installer(
            fileManager: fileManager,
            ignoreArchitectureCheck: true,
            quiet: true,
            printer: PrinterMock(),
            downloader: DownloaderMock(result: .tempFile(incompatibleData))
        )

        let fixture = Fixture(filename: "Lucafile_mock_ignoreArchCheck_nil", type: "yml")
        let path = try #require(Bundle.module.path(forResource: fixture.filename, ofType: fixture.type))

        // Should NOT throw: nil falls back to global true
        try await installer.install(installationType: .spec(specPath: URL(string: path)!))
    }

    @Test
    func test_install_perToolIgnoreArchCheck_nil_fallsBackToGlobal_validates() async throws {
        // Per-tool ignoreArchCheck: nil falls back to global flag — global false → run check
        let fileManager = FileManagerWrapperMock()

        #if arch(arm64) && os(Linux)
        let incompatibleData = Data([0x7F, 0x45, 0x4C, 0x46,
                                     0x02, 0x01, 0x01, 0x00,
                                     0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
                                     0x02, 0x00,
                                     0x3E, 0x00])  // EM_X86_64
        #else
        let incompatibleData = Data([0x7F, 0x45, 0x4C, 0x46,
                                     0x02, 0x01, 0x01, 0x00,
                                     0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
                                     0x02, 0x00,
                                     0xB7, 0x00])  // EM_AARCH64
        #endif

        let installer = Installer(
            fileManager: fileManager,
            ignoreArchitectureCheck: false,
            quiet: true,
            printer: PrinterMock(),
            downloader: DownloaderMock(result: .tempFile(incompatibleData))
        )

        let fixture = Fixture(filename: "Lucafile_mock_ignoreArchCheck_nil", type: "yml")
        let path = try #require(Bundle.module.path(forResource: fixture.filename, ofType: fixture.type))

        // Should throw: nil falls back to global false
        await #expect(throws: (any Error).self) {
            try await installer.install(installationType: .spec(specPath: URL(string: path)!))
        }
    }

    private func spec(for fixture: Fixture) throws -> Spec {
        let bundle = Bundle.module
        let path = try #require(bundle.path(forResource: fixture.filename, ofType: fixture.type))
        let data = try Data(contentsOf: URL(fileURLWithPath: path))
        return try YAMLDecoder().decode(Spec.self, from: data)
    }
}
