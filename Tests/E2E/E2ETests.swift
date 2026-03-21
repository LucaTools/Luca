//  E2ETests.swift

import Foundation
import Testing
@testable import LucaCore

struct E2ETests {

    private let fileManager: FileManaging
    private let installer: Installer
    private let uninstaller: Uninstaller
    private let unlinker: Unlinker
    private let linkedToolsLister: LinkedToolsLister

    // Minimal ELF ARM64 header — FileTypeDetector identifies this as .executable
    private static let mockExecutableData = Data([
        0x7F, 0x45, 0x4C, 0x46,  // ELF magic
        0x02, 0x01, 0x01, 0x00,  // class, encoding, version, OS/ABI
        0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,  // padding
        0x02, 0x00,              // e_type
        0xB7, 0x00               // e_machine = EM_AARCH64
    ])

    init() async throws {
        fileManager = FileManagerWrapperMock()
        let downloader = DownloaderMock(result: .tempFile(Self.mockExecutableData))
        installer = Installer(
            fileManager: fileManager,
            ignoreArchitectureCheck: true,
            quiet: true,
            printer: PrinterMock(),
            downloader: downloader
        )
        uninstaller = Uninstaller(fileManager: fileManager, printer: PrinterMock())
        unlinker = Unlinker(fileManager: fileManager, printer: PrinterMock())
        linkedToolsLister = LinkedToolsLister(fileManager: fileManager)
    }

    // MARK: - Helpers

    private func specPath(fixture: Fixture) throws -> String {
        let bundle = Bundle.module
        return try #require(bundle.path(forResource: fixture.filename, ofType: fixture.type))
    }

    private func cacheURL(toolName: String, version: String) -> URL {
        fileManager.toolsFolder
            .appending(component: toolName)
            .appending(component: version)
    }

    private func symlinkURL(binaryName: String) -> URL {
        fileManager.symlinksFolder.appending(component: binaryName)
    }

    private func installFullSpec() async throws {
        let path = try specPath(fixture: Fixture(filename: "Lucafile_e2e_full", type: "yml"))
        try await installer.install(installationType: ToolInstallationType.spec(specPath: URL(string: path)!))
    }

    // MARK: - Tests

    @Test
    func test_install_thenUninstall_binaryDeletedSymlinkBroken() async throws {
        try await installFullSpec()

        let linkedToolsBefore = try linkedToolsLister.linkedTools()
        #expect(linkedToolsBefore.count == 3)

        try uninstaller.uninstall(tool: "MockToolA", version: "1.0.0")

        // Cache directory no longer exists
        #expect(!fileManager.fileExists(atPath: cacheURL(toolName: "MockToolA", version: "1.0.0").path))

        // Symlink node still exists (lstat sees it) but destination is gone
        let symlinkA = symlinkURL(binaryName: "mock-tool-a")
        let attributes = try fileManager.attributesOfItem(atPath: symlinkA.path)
        let fileType = attributes[.type] as? FileAttributeType
        #expect(fileType == .typeSymbolicLink)

        // LinkedToolsLister still sees MockToolA (broken symlink is parseable)
        let linkedTools = try linkedToolsLister.linkedTools()
        let toolAEntry = linkedTools.first { $0.name == "MockToolA" }
        #expect(toolAEntry != nil)

        // The destination path is gone
        if let toolAEntry {
            #expect(!fileManager.fileExists(atPath: toolAEntry.path))
        }

        // MockToolB and MockToolC are unaffected
        #expect(linkedTools.contains { $0.name == "MockToolB" })
        #expect(linkedTools.contains { $0.name == "MockToolC" })
    }

    @Test
    func test_install_thenUnlink_binaryPreservedNotLinked() async throws {
        try await installFullSpec()

        try unlinker.unlink(symlink: "mock-tool-a")

        // Cache directory and binary still exist
        let cache = cacheURL(toolName: "MockToolA", version: "1.0.0")
        #expect(fileManager.fileExists(atPath: cache.path))
        #expect(fileManager.fileExists(atPath: cache.appending(component: "mock-tool-a").path))

        // MockToolA is no longer linked
        let linkedTools = try linkedToolsLister.linkedTools()
        #expect(!linkedTools.contains { $0.name == "MockToolA" })
        #expect(linkedTools.count == 2)

        // MockToolB and MockToolC remain
        #expect(linkedTools.contains { $0.name == "MockToolB" })
        #expect(linkedTools.contains { $0.name == "MockToolC" })
    }

    @Test
    func test_install_thenUnlink_thenReinstall_toolLinkedAgain() async throws {
        try await installFullSpec()

        try unlinker.unlink(symlink: "mock-tool-a")
        #expect((try linkedToolsLister.linkedTools()).count == 2)

        // Reinstall full spec — binary exists in cache, so reinstall path runs
        try await installFullSpec()

        let linkedTools = try linkedToolsLister.linkedTools()
        #expect(linkedTools.count == 3)

        let toolA = try #require(linkedTools.first { $0.name == "MockToolA" })
        #expect(toolA.version == "1.0.0")
        #expect(toolA.binaryName == "mock-tool-a")

        // Symlink exists and points to correct cache location
        let symlink = symlinkURL(binaryName: "mock-tool-a")
        #expect(fileManager.fileExists(atPath: symlink.path))

        let destination = try fileManager.destinationOfSymbolicLink(atPath: symlink.path)
        let expectedDestination = cacheURL(toolName: "MockToolA", version: "1.0.0")
            .appending(component: "mock-tool-a")
        #expect(destination == expectedDestination.path)
    }

    @Test
    func test_installFullSpec_thenInstallSubsetSpec_orphanedToolUnlinkedButCached() async throws {
        try await installFullSpec()
        #expect((try linkedToolsLister.linkedTools()).count == 3)

        // Install subset spec (MockToolB + MockToolC only)
        let subsetPath = try specPath(fixture: Fixture(filename: "Lucafile_e2e_subset", type: "yml"))
        try await installer.install(installationType: ToolInstallationType.spec(specPath: URL(string: subsetPath)!))

        let linkedTools = try linkedToolsLister.linkedTools()
        #expect(linkedTools.count == 2)
        #expect(!linkedTools.contains { $0.name == "MockToolA" })
        #expect(linkedTools.contains { $0.name == "MockToolB" })
        #expect(linkedTools.contains { $0.name == "MockToolC" })

        // Symlink removed
        #expect(!fileManager.fileExists(atPath: symlinkURL(binaryName: "mock-tool-a").path))

        // Cache preserved
        let cache = cacheURL(toolName: "MockToolA", version: "1.0.0")
        #expect(fileManager.fileExists(atPath: cache.path))
        #expect(fileManager.fileExists(atPath: cache.appending(component: "mock-tool-a").path))
    }

    @Test
    func test_install_unlinkOne_otherToolsUnaffected() async throws {
        try await installFullSpec()

        try unlinker.unlink(symlink: "mock-tool-a")

        let linkedTools = try linkedToolsLister.linkedTools()
        #expect(linkedTools.count == 2)

        let toolB = try #require(linkedTools.first { $0.name == "MockToolB" })
        #expect(toolB.version == "2.0.0")
        #expect(toolB.binaryName == "mock-tool-b")

        let toolC = try #require(linkedTools.first { $0.name == "MockToolC" })
        #expect(toolC.version == "3.0.0")
        #expect(toolC.binaryName == "mock-tool-c")

        // Caches untouched
        #expect(fileManager.fileExists(atPath: cacheURL(toolName: "MockToolB", version: "2.0.0").path))
        #expect(fileManager.fileExists(atPath: cacheURL(toolName: "MockToolC", version: "3.0.0").path))
    }

    @Test
    func test_install_thenUninstall_thenReinstall_toolRedownloadedAndLinked() async throws {
        try await installFullSpec()

        try uninstaller.uninstall(tool: "MockToolA", version: "1.0.0")
        #expect(!fileManager.fileExists(atPath: cacheURL(toolName: "MockToolA", version: "1.0.0").path))

        // Reinstall — cache missing, so full download + install path runs
        try await installFullSpec()

        let cache = cacheURL(toolName: "MockToolA", version: "1.0.0")
        #expect(fileManager.fileExists(atPath: cache.path))
        #expect(fileManager.fileExists(atPath: cache.appending(component: "mock-tool-a").path))

        let linkedTools = try linkedToolsLister.linkedTools()
        #expect(linkedTools.count == 3)

        let toolA = try #require(linkedTools.first { $0.name == "MockToolA" })
        #expect(toolA.version == "1.0.0")
        #expect(toolA.binaryName == "mock-tool-a")
    }
}
