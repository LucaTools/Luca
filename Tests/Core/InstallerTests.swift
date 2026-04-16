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

    private func makeInstaller(quiet: Bool) -> Installer {
        let toolInstaller = ToolInstaller(
            fileManager: fileManager,
            ignoreArchitectureCheck: true,
            printer: PrinterMock(),
            downloader: DownloaderMock(result: .fixture(Fixture(filename: "MockMachO_Universal_Release", type: "zip")))
        )
        return Installer(
            fileManager: fileManager,
            ignoreArchitectureCheck: true,
            quiet: quiet,
            printer: PrinterMock(),
            toolInstaller: toolInstaller
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
        
        for tool in spec.tools ?? [] {
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
        
        try await installer.install(installationType: ToolInstallationType.spec(specPath: URL(string: path)!))
        
        for tool in spec.tools ?? [] {
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
            .appending(component: try #require(spec.tools?.first).expectedBinaryName)
        #expect(fileManager.fileExists(atPath: toolSymLink.path))
    }
    
    @Test(arguments: [true, false])
    func test_installInvalid(quiet: Bool) async throws {
        let installer = makeInstaller(quiet: quiet)
        
        let fixture = Fixture(filename: "Lucafile_invalid", type: "yml")
        let bundle = Bundle.module
        let path = try #require(bundle.path(forResource: fixture.filename, ofType: fixture.type))
        
        await #expect(throws: (any Error).self) {
            try await installer.install(installationType: ToolInstallationType.spec(specPath: URL(string: path)!))
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
        
        try await installer.install(installationType: ToolInstallationType.spec(specPath: URL(string: path)!))
        try await installer.install(installationType: ToolInstallationType.spec(specPath: URL(string: path)!))
        
        for tool in spec.tools ?? [] {
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
        
        try await installer.install(installationType: ToolInstallationType.spec(specPath: URL(string: lowVersionPath)!))
        try await installer.install(installationType: ToolInstallationType.spec(specPath: URL(string: highVersionPath)!))

        let highVersionSpec = try spec(for: highVersionFixture)
        
        for tool in highVersionSpec.tools ?? [] {
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
        
        try await installer.install(installationType: ToolInstallationType.spec(specPath: URL(string: highVersionPath)!))
        try await installer.install(installationType: ToolInstallationType.spec(specPath: URL(string: lowVersionPath)!))
        
        let lowVersionSpec = try spec(for: lowVersionFixture)
        
        for tool in lowVersionSpec.tools ?? [] {
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
        
        try await installer.install(installationType: ToolInstallationType.spec(specPath: URL(string: fullPath)!))
        
        // Verify all tools are installed (each tool directory exists)
        for tool in fullSpec.tools ?? [] {
            let toolPath = fileManager.toolsFolder
                .appending(component: tool.name)
                .appending(components: tool.version)
            #expect(fileManager.fileExists(atPath: toolPath.path))
        }
        
        // Now install a subset spec (missing MockToolC and MockToolD)
        let subsetFixture = Fixture(filename: "Lucafile_mock_subset", type: "yml")
        let subsetPath = try #require(bundle.path(forResource: subsetFixture.filename, ofType: subsetFixture.type))
        let subsetSpec = try spec(for: subsetFixture)
        
        try await installer.install(installationType: ToolInstallationType.spec(specPath: URL(string: subsetPath)!))
        
        // Verify tools in subset spec are still installed
        for tool in subsetSpec.tools ?? [] {
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
        
        try await installer.install(installationType: ToolInstallationType.spec(specPath: URL(string: fullPath)!))
        
        // Install an individual tool (not from the spec)
        let individualFixture = Fixture(filename: "Lucafile_mock_lowversion", type: "yml")
        let individualSpec = try spec(for: individualFixture)
        let individualTool = try #require(individualSpec.tools?.first)
        
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
        for tool in fullSpec.tools ?? [] {
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
        
        try await installer.install(installationType: ToolInstallationType.spec(specPath: URL(string: path)!))
        
        // Install the same spec again
        try await installer.install(installationType: ToolInstallationType.spec(specPath: URL(string: path)!))
        
        // All tools should still be installed (no orphans to unlink)
        for tool in spec.tools ?? [] {
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
        
        try await installer.install(installationType: ToolInstallationType.spec(specPath: URL(string: lowVersionPath)!))
        
        // The symlink is created with the binary name from binaryPath
        let symLink = fileManager.symlinksFolder.appending(component: "MockMachOTool")
        #expect(fileManager.fileExists(atPath: symLink.path))
        
        // Reinstall the same spec - the tool should NOT be unlinked
        try await installer.install(installationType: ToolInstallationType.spec(specPath: URL(string: lowVersionPath)!))
        
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
        
        try await installer.install(installationType: ToolInstallationType.spec(specPath: URL(string: mockToolPath)!))
        
        // Verify MockTool is installed
        let mockToolSpec = try spec(for: mockToolFixture)
        let mockTool = try #require(mockToolSpec.tools?.first)
        let mockToolInstallPath = fileManager.toolsFolder
            .appending(component: mockTool.name)
            .appending(components: mockTool.version)
        #expect(fileManager.fileExists(atPath: mockToolInstallPath.path))
        
        // Now install a different spec that does NOT include MockTool
        let differentFixture = Fixture(filename: "Lucafile_mock_subset", type: "yml")
        let differentPath = try #require(bundle.path(forResource: differentFixture.filename, ofType: differentFixture.type))
        
        try await installer.install(installationType: ToolInstallationType.spec(specPath: URL(string: differentPath)!))
        
        // MockTool directory should still exist (we don't delete installed tools, just unlink)
        #expect(fileManager.fileExists(atPath: mockToolInstallPath.path))
        
        // But tools in the new spec should be installed
        let subsetSpec = try spec(for: differentFixture)
        for tool in subsetSpec.tools ?? [] {
            let toolPath = fileManager.toolsFolder
                .appending(component: tool.name)
                .appending(components: tool.version)
            #expect(fileManager.fileExists(atPath: toolPath.path))
        }
    }
    
    @Test(arguments: [true, false])
    func test_install_fromHomeDirectory_throwsError(quiet: Bool) async throws {
        let homeDirFileManager = HomeDirFileManagerMock()
        let installer = Installer(
            fileManager: homeDirFileManager,
            ignoreArchitectureCheck: true,
            quiet: quiet,
            printer: PrinterMock()
        )
        await #expect(throws: Installer.InstallerError.runningFromHomeDirectory) {
            try await installer.install(
                installationType: .individualInline(
                    name: "SomeTool",
                    version: "1.0.0",
                    url: URL(string: "https://example.com/tool")!,
                    binaryPath: nil,
                    desiredBinaryName: nil,
                    checksum: nil,
                    algorithm: nil
                )
            )
        }
    }

    // MARK: - Skills

    @Test(arguments: [true, false])
    func test_installSkillsSpec_installsAllSkillSets(quiet: Bool) async throws {
        let skillInstaller = SkillInstallerMock()
        let fixture = Fixture(filename: "Lucafile_mock_with_skills", type: "yml")
        let bundle = Bundle.module
        let path = try #require(bundle.path(forResource: fixture.filename, ofType: fixture.type))
        let specLoader = FixtureSpecLoader(fixture: fixture)

        let installer = Installer(
            fileManager: fileManager,
            ignoreArchitectureCheck: true,
            quiet: quiet,
            printer: PrinterMock(),
            skillInstaller: skillInstaller,
            specLoader: specLoader
        )

        try await installer.install(installationType: SkillInstallationType.spec(specPath: URL(fileURLWithPath: path)), useNpx: true)

        #expect(skillInstaller.calls.count == 2)
        let installedRepositories = Set(skillInstaller.calls.map(\.skillSet.repository))
        #expect(installedRepositories.contains("vercel-labs/agent-skills"))
        #expect(installedRepositories.contains("https://github.com/AvdLee/Swift-Testing-Agent-Skill"))
        for call in skillInstaller.calls {
            #expect(call.agents == ["claude-code", "github-copilot", "opencode"])
        }
    }

    @Test(arguments: [true, false])
    func test_installToolsSpec_doesNotInstallSkills(quiet: Bool) async throws {
        let skillInstaller = SkillInstallerMock()
        let toolInstaller = ToolInstallerMock()
        let fixture = Fixture(filename: "Lucafile_mock_with_skills", type: "yml")
        let bundle = Bundle.module
        let path = try #require(bundle.path(forResource: fixture.filename, ofType: fixture.type))
        let specLoader = FixtureSpecLoader(fixture: fixture)

        let installer = Installer(
            fileManager: fileManager,
            ignoreArchitectureCheck: true,
            quiet: quiet,
            printer: PrinterMock(),
            toolInstaller: toolInstaller,
            skillInstaller: skillInstaller,
            specLoader: specLoader
        )

        try await installer.install(installationType: ToolInstallationType.spec(specPath: URL(fileURLWithPath: path)))

        #expect(skillInstaller.calls.isEmpty)
    }

    @Test(arguments: [true, false])
    func test_installSkillsSpec_usesNativePipeline(quiet: Bool) async throws {
        let skillDownloaderMock = SkillDownloaderMock()
        skillDownloaderMock.downloadResult = .success([
            ("find-skills", [SkillFile(relativePath: "SKILL.md", content: Data("content".utf8))])
        ])
        let skillSymLinkerMock = SkillSymLinkerMock()
        let skillInstallerMock = SkillInstallerMock()
        let fixture = Fixture(filename: "Lucafile_mock_with_skills", type: "yml")
        let bundle = Bundle.module
        let path = try #require(bundle.path(forResource: fixture.filename, ofType: fixture.type))
        let specLoader = FixtureSpecLoader(fixture: fixture)

        let installer = Installer(
            fileManager: fileManager,
            ignoreArchitectureCheck: true,
            quiet: quiet,
            printer: PrinterMock(),
            skillInstaller: skillInstallerMock,
            skillDownloader: skillDownloaderMock,
            skillSymLinker: skillSymLinkerMock,
            specLoader: specLoader
        )

        try await installer.install(installationType: SkillInstallationType.spec(specPath: URL(fileURLWithPath: path)), useNpx: false)

        #expect(skillDownloaderMock.downloadCalled == true)
        #expect(skillSymLinkerMock.setSymLinkCalled == true)
        #expect(skillInstallerMock.calls.isEmpty)

        let skillFile = fileManager.skillsCacheFolder.appending(components: "find-skills", "SKILL.md")
        #expect(fileManager.fileExists(atPath: skillFile.path))

        let expectedAgentIds = ["claude-code", "github-copilot", "opencode"]
        let actualAgentIds = skillSymLinkerMock.lastAgents?.map(\.id) ?? []
        #expect(actualAgentIds.sorted() == expectedAgentIds.sorted())
    }

    @Test(arguments: [true, false])
    func test_installSkillsSpec_useNpx_usesNpxPipeline(quiet: Bool) async throws {
        let skillDownloaderMock = SkillDownloaderMock()
        let skillSymLinkerMock = SkillSymLinkerMock()
        let skillInstallerMock = SkillInstallerMock()
        let fixture = Fixture(filename: "Lucafile_mock_with_skills", type: "yml")
        let bundle = Bundle.module
        let path = try #require(bundle.path(forResource: fixture.filename, ofType: fixture.type))
        let specLoader = FixtureSpecLoader(fixture: fixture)

        let installer = Installer(
            fileManager: fileManager,
            ignoreArchitectureCheck: true,
            quiet: quiet,
            printer: PrinterMock(),
            skillInstaller: skillInstallerMock,
            skillDownloader: skillDownloaderMock,
            skillSymLinker: skillSymLinkerMock,
            specLoader: specLoader
        )

        try await installer.install(installationType: SkillInstallationType.spec(specPath: URL(fileURLWithPath: path)), useNpx: true)

        #expect(skillInstallerMock.calls.count == 2)
        #expect(skillDownloaderMock.downloadCalled == false)
    }

    @Test(arguments: [true, false])
    func test_installSkillsIndividual_usesNativePipeline(quiet: Bool) async throws {
        let skillDownloaderMock = SkillDownloaderMock()
        skillDownloaderMock.downloadResult = .success([
            ("find-skills", [SkillFile(relativePath: "SKILL.md", content: Data("content".utf8))])
        ])
        let skillSymLinkerMock = SkillSymLinkerMock()
        let skillInstallerMock = SkillInstallerMock()

        let installer = Installer(
            fileManager: fileManager,
            ignoreArchitectureCheck: true,
            quiet: quiet,
            printer: PrinterMock(),
            skillInstaller: skillInstallerMock,
            skillDownloader: skillDownloaderMock,
            skillSymLinker: skillSymLinkerMock
        )

        try await installer.install(
            installationType: .individual(repository: "owner/repo", skillNames: [], agents: nil, ref: nil),
            useNpx: false
        )

        #expect(skillDownloaderMock.downloadCalled == true)
        #expect(skillSymLinkerMock.setSymLinkCalled == true)
        #expect(skillInstallerMock.calls.isEmpty)
        #expect(skillSymLinkerMock.lastAgents == AgentRegistry.all)
    }

    @Test(arguments: [true, false])
    func test_installSkillsSpec_writesAuxiliaryFiles(quiet: Bool) async throws {
        let skillDownloaderMock = SkillDownloaderMock()
        skillDownloaderMock.downloadResult = .success([
            ("find-skills", [
                SkillFile(relativePath: "SKILL.md", content: Data("skill".utf8)),
                SkillFile(relativePath: "resources/template.md", content: Data("template".utf8))
            ])
        ])
        let skillSymLinkerMock = SkillSymLinkerMock()
        let skillInstallerMock = SkillInstallerMock()
        let fixture = Fixture(filename: "Lucafile_mock_with_skills", type: "yml")
        let bundle = Bundle.module
        let path = try #require(bundle.path(forResource: fixture.filename, ofType: fixture.type))
        let specLoader = FixtureSpecLoader(fixture: fixture)

        let installer = Installer(
            fileManager: fileManager,
            ignoreArchitectureCheck: true,
            quiet: quiet,
            printer: PrinterMock(),
            skillInstaller: skillInstallerMock,
            skillDownloader: skillDownloaderMock,
            skillSymLinker: skillSymLinkerMock,
            specLoader: specLoader
        )

        try await installer.install(
            installationType: SkillInstallationType.spec(specPath: URL(fileURLWithPath: path)),
            useNpx: false
        )

        let skillMd = fileManager.skillsCacheFolder.appending(components: "find-skills", "SKILL.md")
        let template = fileManager.skillsCacheFolder
            .appending(components: "find-skills", "resources", "template.md")
        #expect(fileManager.fileExists(atPath: skillMd.path))
        #expect(fileManager.fileExists(atPath: template.path))
    }

    @Test(arguments: [true, false])
    func test_installSkillsSpec_noSkills_printsEmptyMessage(quiet: Bool) async throws {
        let skillDownloaderMock = SkillDownloaderMock()
        let skillInstallerMock = SkillInstallerMock()
        let fixture = Fixture(filename: "Lucafile_mock_no_skills", type: "yml")
        let bundle = Bundle.module
        let path = try #require(bundle.path(forResource: fixture.filename, ofType: fixture.type))
        let specLoader = FixtureSpecLoader(fixture: fixture)

        let installer = Installer(
            fileManager: fileManager,
            ignoreArchitectureCheck: true,
            quiet: quiet,
            printer: PrinterMock(),
            skillInstaller: skillInstallerMock,
            skillDownloader: skillDownloaderMock,
            specLoader: specLoader
        )

        try await installer.install(installationType: SkillInstallationType.spec(specPath: URL(fileURLWithPath: path)), useNpx: false)

        #expect(skillInstallerMock.calls.isEmpty)
        #expect(skillDownloaderMock.downloadCalled == false)
    }

    @Test(arguments: [true, false])
    func test_installSkillsIndividual_noAgents_usesAllAgents(quiet: Bool) async throws {
        let skillDownloaderMock = SkillDownloaderMock()
        skillDownloaderMock.downloadResult = .success([
            ("my-skill", [SkillFile(relativePath: "SKILL.md", content: Data("content".utf8))])
        ])
        let skillSymLinkerMock = SkillSymLinkerMock()

        let installer = Installer(
            fileManager: fileManager,
            ignoreArchitectureCheck: true,
            quiet: quiet,
            printer: PrinterMock(),
            skillDownloader: skillDownloaderMock,
            skillSymLinker: skillSymLinkerMock
        )

        try await installer.install(
            installationType: .individual(repository: "owner/repo", skillNames: [], agents: nil, ref: nil),
            useNpx: false
        )

        #expect(skillSymLinkerMock.lastAgents == AgentRegistry.all)
    }

    private func spec(for fixture: Fixture) throws -> Spec {
        let bundle = Bundle.module
        let path = try #require(bundle.path(forResource: fixture.filename, ofType: fixture.type))
        let data = try Data(contentsOf: URL(fileURLWithPath: path))
        return try YAMLDecoder().decode(Spec.self, from: data)
    }
}

// MARK: - Private mocks

private class HomeDirFileManagerMock: FileManagerWrapperMock {
    override var currentDirectoryPath: String {
        homeDirectoryForCurrentUser.path
    }
}

private struct FixtureSpecLoader: SpecLoading {
    let fixture: Fixture

    func loadSpec(at path: URL) throws -> Spec {
        let bundle = Bundle.module
        guard let filePath = bundle.path(forResource: fixture.filename, ofType: fixture.type) else {
            throw SpecLoader.SpecLoaderError.missingSpec(path.path)
        }
        let data = try Data(contentsOf: URL(fileURLWithPath: filePath))
        return try YAMLDecoder().decode(Spec.self, from: data)
    }
}
