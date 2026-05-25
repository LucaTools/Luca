//  ToolInstallerTests.swift

import Foundation
import Testing
@testable import LucaFoundation
@testable import ManagerCore

struct ToolInstallerTests {

    private func makeToolInstaller(
        fileManager: FileManaging,
        ignoreArchitectureCheck: Bool,
        downloader: Downloading
    ) -> ToolInstaller {
        ToolInstaller(
            fileManager: fileManager,
            ignoreArchitectureCheck: ignoreArchitectureCheck,
            printer: PrinterMock(),
            downloader: downloader
        )
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

        let toolInstaller = makeToolInstaller(
            fileManager: fileManager,
            ignoreArchitectureCheck: true,
            downloader: DownloaderMock(result: .tempFile(executableData))
        )

        let tool = Tool(
            name: toolName,
            version: version,
            url: url,
            binaryPath: nil,
            desiredBinaryName: desiredBinaryName,
            checksum: nil,
            algorithm: nil,
            ignoreArchCheck: nil
        )

        // First install: covers installExecutable path
        try await toolInstaller.install(tool: tool)

        let binaryPath = fileManager.toolsFolder.appending(components: toolName, version, desiredBinaryName)
        #expect(fileManager.fileExists(atPath: binaryPath.path))

        let symLinkPath = fileManager.symlinksFolder.appending(component: desiredBinaryName)
        #expect(fileManager.fileExists(atPath: symLinkPath.path))
    }

    @Test
    func test_install_archiveNilBinaryPath_usesBinaryFinder() async throws {
        let fileManager = FileManagerWrapperMock()
        let toolInstaller = makeToolInstaller(
            fileManager: fileManager,
            ignoreArchitectureCheck: true,
            downloader: DownloaderMock(result: .fixture(Fixture(filename: "MockMachO_Universal_Release", type: "zip")))
        )
        let toolName = "TestArchiveTool"
        let version = "1.0.0"

        let tool = Tool(
            name: toolName,
            version: version,
            url: URL(string: "https://example.com/tool.zip")!,
            binaryPath: nil,        // triggers binaryFinder.findBinary in installArchive
            desiredBinaryName: nil,
            checksum: nil,
            algorithm: nil,
            ignoreArchCheck: nil
        )
        try await toolInstaller.install(tool: tool)

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

        let toolInstaller = makeToolInstaller(
            fileManager: fileManager,
            ignoreArchitectureCheck: true,
            downloader: DownloaderMock(result: .tempFile(executableData))
        )

        let tool = Tool(
            name: toolName,
            version: "1.0.0",
            url: URL(string: "https://example.com/tool")!,
            binaryPath: nil,
            desiredBinaryName: nil,    // triggers `return tool.name` in installExecutable
            checksum: nil,
            algorithm: nil,
            ignoreArchCheck: nil
        )
        try await toolInstaller.install(tool: tool)

        let binaryPath = fileManager.toolsFolder.appending(components: toolName, "1.0.0", toolName)
        #expect(fileManager.fileExists(atPath: binaryPath.path))
        let symLinkPath = fileManager.symlinksFolder.appending(component: toolName)
        #expect(fileManager.fileExists(atPath: symLinkPath.path))
    }

    /// Regression test: when a direct-binary tool has `binaryPath` set but no `desiredBinaryName`
    /// (e.g. `name: "FirebaseCLI"`, `binaryPath: "firebase"`), the binary must be stored under
    /// the `binaryPath` name so that `isToolInstalled` can find it and avoids re-downloading
    /// on every run.
    @Test
    func test_install_executableWithBinaryPath_storesBinaryUnderBinaryPathName() async throws {
        let fileManager = FileManagerWrapperMock()
        let toolName = "FirebaseCLI"
        let binaryPathName = "firebase"
        let version = "14.12.1"

        let executableData = Data([0x7F, 0x45, 0x4C, 0x46,
                                   0x02, 0x01, 0x01, 0x00,
                                   0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
                                   0x02, 0x00, 0xB7, 0x00])

        let toolInstaller = makeToolInstaller(
            fileManager: fileManager,
            ignoreArchitectureCheck: true,
            downloader: DownloaderMock(result: .tempFile(executableData))
        )

        let tool = Tool(
            name: toolName,
            version: version,
            url: URL(string: "https://example.com/firebase-tools-macos")!,
            binaryPath: binaryPathName,
            desiredBinaryName: nil,
            checksum: nil,
            algorithm: nil,
            ignoreArchCheck: nil
        )

        try await toolInstaller.install(tool: tool)

        // Binary must be stored as "firebase", not "FirebaseCLI"
        let binaryPath = fileManager.toolsFolder.appending(components: toolName, version, binaryPathName)
        #expect(fileManager.fileExists(atPath: binaryPath.path))

        // Symlink must be named "firebase"
        let symLinkPath = fileManager.symlinksFolder.appending(component: binaryPathName)
        #expect(fileManager.fileExists(atPath: symLinkPath.path))

        let wrongPath = fileManager.toolsFolder.appending(components: toolName, version, toolName)
        #expect(!fileManager.fileExists(atPath: wrongPath.path), "Binary must NOT be stored under tool name")
    }

    /// Regression test: when an archive tool has both `binaryPath` and `desiredBinaryName` set
    /// (e.g. Phrase CLI where `binaryPath: "phrase_macosx_arm64"`, `desiredBinaryName: "phrase"`),
    /// the symlink must use `desiredBinaryName`, not the in-archive binary name.
    @Test
    func test_install_archiveWithDesiredBinaryName_usesDesiredNameForSymlink() async throws {
        let fileManager = FileManagerWrapperMock()
        let toolInstaller = makeToolInstaller(
            fileManager: fileManager,
            ignoreArchitectureCheck: true,
            downloader: DownloaderMock(result: .fixture(Fixture(filename: "MockMachO_Universal_Release", type: "zip")))
        )
        let toolName = "Phrase"
        let version = "2.59.0"
        let desiredBinaryName = "phrase"

        let tool = Tool(
            name: toolName,
            version: version,
            url: URL(string: "https://example.com/phrase_macosx_arm64.zip")!,
            binaryPath: "bin/MockMachOTool",
            desiredBinaryName: desiredBinaryName,
            checksum: nil,
            algorithm: nil,
            ignoreArchCheck: nil
        )
        try await toolInstaller.install(tool: tool)

        let symLinkPath = fileManager.symlinksFolder.appending(component: desiredBinaryName)
        #expect(fileManager.fileExists(atPath: symLinkPath.path), "Symlink must be named '\(desiredBinaryName)'")

        let wrongSymLink = fileManager.symlinksFolder.appending(component: "MockMachOTool")
        #expect(!fileManager.fileExists(atPath: wrongSymLink.path), "Symlink must NOT use the in-archive binary name")
    }

    @Test
    func test_install_unknownFileType_throws() async throws {
        let fileManager = FileManagerWrapperMock()

        // Unknown magic bytes — FileTypeDetector returns nil → ToolInstallerError.unknownFileType
        let unknownData = Data([0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07, 0x08])

        let toolInstaller = makeToolInstaller(
            fileManager: fileManager,
            ignoreArchitectureCheck: true,
            downloader: DownloaderMock(result: .tempFile(unknownData))
        )

        let tool = Tool(
            name: "SomeTool",
            version: "1.0.0",
            url: URL(string: "https://example.com/tool")!,
            binaryPath: nil,
            desiredBinaryName: nil,
            checksum: nil,
            algorithm: nil,
            ignoreArchCheck: nil
        )

        await #expect(throws: (any Error).self) {
            try await toolInstaller.install(tool: tool)
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

        let toolInstaller = makeToolInstaller(
            fileManager: fileManager,
            ignoreArchitectureCheck: false,
            downloader: DownloaderMock(result: .tempFile(incompatibleData))
        )

        let tool = Tool(
            name: "SomeTool",
            version: "1.0.0",
            url: URL(string: "https://example.com/tool")!,
            binaryPath: nil,
            desiredBinaryName: "sometool",
            checksum: nil,
            algorithm: nil,
            ignoreArchCheck: nil
        )

        await #expect(throws: (any Error).self) {
            try await toolInstaller.install(tool: tool)
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

        let toolInstaller = makeToolInstaller(
            fileManager: fileManager,
            ignoreArchitectureCheck: false,
            downloader: DownloaderMock(result: .tempFile(incompatibleData))
        )

        let tool = Tool(
            name: "SomeTool",
            version: "1.0.0",
            url: URL(string: "https://example.com/tool")!,
            binaryPath: nil,
            desiredBinaryName: "sometool",
            checksum: nil,
            algorithm: nil,
            ignoreArchCheck: true  // per-tool true overrides global false
        )

        // Should NOT throw: per-tool true overrides global false
        try await toolInstaller.install(tool: tool)
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

        let toolInstaller = makeToolInstaller(
            fileManager: fileManager,
            ignoreArchitectureCheck: true,
            downloader: DownloaderMock(result: .tempFile(incompatibleData))
        )

        let tool = Tool(
            name: "SomeTool",
            version: "1.0.0",
            url: URL(string: "https://example.com/tool")!,
            binaryPath: nil,
            desiredBinaryName: "sometool",
            checksum: nil,
            algorithm: nil,
            ignoreArchCheck: false  // per-tool false overrides global true
        )

        // Should throw: per-tool false overrides global true
        await #expect(throws: (any Error).self) {
            try await toolInstaller.install(tool: tool)
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

        let toolInstaller = makeToolInstaller(
            fileManager: fileManager,
            ignoreArchitectureCheck: true,
            downloader: DownloaderMock(result: .tempFile(incompatibleData))
        )

        let tool = Tool(
            name: "SomeTool",
            version: "1.0.0",
            url: URL(string: "https://example.com/tool")!,
            binaryPath: nil,
            desiredBinaryName: "sometool",
            checksum: nil,
            algorithm: nil,
            ignoreArchCheck: nil  // nil falls back to global true
        )

        // Should NOT throw: nil falls back to global true
        try await toolInstaller.install(tool: tool)
    }

    /// Regression test: when a tool's `binaryPath` points to a shell-script wrapper
    /// (not an ELF/Mach-O binary), `reinstall` must honour `binaryPath` for the symlink
    /// rather than falling back to `BinaryFinder`, which would skip the script and pick
    /// the first real binary it finds in the tool directory instead
    /// (e.g. `jre/bin/java` in SonarScannerCLI's case).
    @Test
    func test_reinstall_archiveToolWithBinaryPath_respectsBinaryPath() async throws {
        let fileManager = FileManagerWrapperMock()
        let toolName = "SonarScannerCLI"
        let version = "7.0.0"
        let binaryPathValue = "sonar-scanner"

        // Manually build the "already installed" state to simulate a tool whose archive
        // ships a shell-script launcher alongside a real JVM binary.
        let installPath = fileManager.toolsFolder.appending(components: toolName, version)
        try FileManager.default.createDirectory(atPath: installPath.path, withIntermediateDirectories: true)

        // sonar-scanner: a shell script (not Mach-O/ELF). isToolInstalled finds it via
        // binaryPath, but BinaryFinder rejects it because it lacks binary magic bytes.
        let scriptPath = installPath.appending(component: binaryPathValue)
        _ = FileManager.default.createFile(atPath: scriptPath.path,
                                            contents: "#!/bin/bash\nexec java \"$@\"".data(using: .utf8))
        try FileManager.default.setAttributes([.posixPermissions: 0o755], ofItemAtPath: scriptPath.path)

        // java: a real Mach-O binary that BinaryFinder would find instead of the script.
        let javaPath = installPath.appending(component: "java")
        _ = FileManager.default.createFile(atPath: javaPath.path,
                                            contents: Data([0xCF, 0xFA, 0xED, 0xFE, 0x00, 0x00, 0x00, 0x00]))
        try FileManager.default.setAttributes([.posixPermissions: 0o755], ofItemAtPath: javaPath.path)

        let toolInstaller = makeToolInstaller(
            fileManager: fileManager,
            ignoreArchitectureCheck: true,
            downloader: DownloaderMock(result: .tempFile(Data()))
        )

        let tool = Tool(
            name: toolName,
            version: version,
            url: URL(string: "https://example.com/sonar-scanner-cli.zip")!,
            binaryPath: binaryPathValue,
            desiredBinaryName: nil,
            checksum: nil,
            algorithm: nil,
            ignoreArchCheck: nil
        )

        try toolInstaller.reinstall(tool: tool)

        // Symlink must be named "sonar-scanner" (binaryPath), NOT "java" (BinaryFinder result)
        let correctSymLink = fileManager.symlinksFolder.appending(component: "sonar-scanner")
        #expect(fileManager.fileExists(atPath: correctSymLink.path))

        let wrongSymLink = fileManager.symlinksFolder.appending(component: "java")
        #expect(!fileManager.fileExists(atPath: wrongSymLink.path),
                "reinstall must not use BinaryFinder when binaryPath is configured")
    }

    /// Regression: `reinstall` must use `desiredBinaryName` (the renamed on-disk file),
    /// not `binaryPath` (the in-archive name that no longer exists after the first install).
    @Test
    func test_reinstall_withDesiredBinaryName_usesDesiredNameForSymlink() throws {
        let fileManager = FileManagerWrapperMock()
        let toolName = "Phrase"
        let version = "2.59.0"
        let desiredBinaryName = "phrase"

        // Simulate the post-install state: binary exists under desiredBinaryName, not binaryPath.
        let versionFolder = fileManager.toolsFolder.appending(components: toolName, version)
        try fileManager.createDirectory(at: versionFolder, withIntermediateDirectories: true)
        let binaryFile = versionFolder.appending(component: desiredBinaryName)
        _ = fileManager.createFile(atPath: binaryFile.path, contents: Data([0x00]))

        let toolInstaller = makeToolInstaller(
            fileManager: fileManager,
            ignoreArchitectureCheck: true,
            downloader: DownloaderMock(result: .tempFile(Data()))
        )

        let tool = Tool(
            name: toolName,
            version: version,
            url: URL(string: "https://example.com/phrase_macosx_arm64.zip")!,
            binaryPath: "phrase_macosx_arm64",   // in-archive name; absent on disk after install
            desiredBinaryName: desiredBinaryName,
            checksum: nil,
            algorithm: nil,
            ignoreArchCheck: nil
        )

        try toolInstaller.reinstall(tool: tool)

        let symLinkPath = fileManager.symlinksFolder.appending(component: desiredBinaryName)
        #expect(fileManager.fileExists(atPath: symLinkPath.path), "Symlink must be named '\(desiredBinaryName)'")
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

        let toolInstaller = makeToolInstaller(
            fileManager: fileManager,
            ignoreArchitectureCheck: false,
            downloader: DownloaderMock(result: .tempFile(incompatibleData))
        )

        let tool = Tool(
            name: "SomeTool",
            version: "1.0.0",
            url: URL(string: "https://example.com/tool")!,
            binaryPath: nil,
            desiredBinaryName: "sometool",
            checksum: nil,
            algorithm: nil,
            ignoreArchCheck: nil  // nil falls back to global false
        )

        // Should throw: nil falls back to global false
        await #expect(throws: (any Error).self) {
            try await toolInstaller.install(tool: tool)
        }
    }
}
