//  SelfUpdaterTests.swift

import Foundation
import Testing
@testable import LucaCore

struct SelfUpdaterTests {

    // MARK: - Helpers

    private func makeSUT(
        fileManager: SelfUpdaterFileManagerMock = SelfUpdaterFileManagerMock(),
        fileDownloaderResult: FileDownloadingMock.Result = .success(
            FileManager.default.temporaryDirectory.appendingPathComponent("test-luca.zip")
        ),
        subprocessExitCodes: [Int32] = [0],
        sudoExitCode: Int32 = 0
    ) -> (sut: SelfUpdater, fileManager: SelfUpdaterFileManagerMock, subprocess: SubprocessRunnerMock, sudo: SudoInstallerMock) {
        let fileDownloader = FileDownloadingMock(result: fileDownloaderResult)
        let subprocess = SubprocessRunnerMock()
        subprocess.exitCodes = subprocessExitCodes
        let sudo = SudoInstallerMock()
        sudo.exitCode = sudoExitCode
        let sut = SelfUpdater(
            fileManager: fileManager,
            fileDownloader: fileDownloader,
            subprocessRunner: subprocess,
            sudoInstaller: sudo,
            printer: PrinterMock()
        )
        return (sut, fileManager, subprocess, sudo)
    }

    // MARK: - Skip conditions

    @Test
    func test_updateIfNeeded_noVersionFile_skips() async throws {
        let (sut, fileManager, subprocess, _) = makeSUT()
        fileManager.stubbedVersionFileContent = nil

        try await sut.updateIfNeeded(currentVersion: "0.0.1")

        #expect(subprocess.recordedArguments.isEmpty)
    }

    @Test
    func test_updateIfNeeded_emptyVersionFile_skips() async throws {
        let (sut, fileManager, subprocess, _) = makeSUT()
        fileManager.stubbedVersionFileContent = "   \n"

        try await sut.updateIfNeeded(currentVersion: "0.0.1")

        #expect(subprocess.recordedArguments.isEmpty)
    }

    @Test
    func test_updateIfNeeded_versionMatches_skips() async throws {
        let (sut, fileManager, subprocess, _) = makeSUT()
        fileManager.stubbedVersionFileContent = "0.0.1"

        try await sut.updateIfNeeded(currentVersion: "0.0.1")

        #expect(subprocess.recordedArguments.isEmpty)
    }

    // MARK: - Validation

    @Test(arguments: ["not-semver", "1.2", "1.2.3.4", "v1.2.3", "1.2.x"])
    func test_updateIfNeeded_invalidVersionFormat_throws(version: String) async throws {
        let (sut, fileManager, _, _) = makeSUT()
        fileManager.stubbedVersionFileContent = version

        await #expect(throws: SelfUpdater.SelfUpdaterError.invalidVersionFormat(version)) {
            try await sut.updateIfNeeded(currentVersion: "0.0.1")
        }
    }

    // MARK: - Writable destination

    @Test
    func test_updateIfNeeded_writableDestination_movesFile() async throws {
        let (sut, fileManager, subprocess, sudo) = makeSUT(subprocessExitCodes: [0])
        fileManager.stubbedVersionFileContent = "1.0.0"
        fileManager.stubbedIsWritable = true

        try await sut.updateIfNeeded(currentVersion: "0.0.1")

        // One subprocess call (unzip only — sudo not used)
        #expect(subprocess.recordedArguments.count == 1)
        #expect(subprocess.recordedArguments[0].first == "unzip")
        #expect(sudo.calls.isEmpty)
        // Binary moved via fileManager
        #expect(fileManager.movedItems.count == 1)
    }

    @Test
    func test_updateIfNeeded_writableDestination_setsExecutablePermissions() async throws {
        let (sut, fileManager, _, _) = makeSUT(subprocessExitCodes: [0])
        fileManager.stubbedVersionFileContent = "1.0.0"
        fileManager.stubbedIsWritable = true

        try await sut.updateIfNeeded(currentVersion: "0.0.1")

        let permissionsCall = try #require(fileManager.setAttributesCalls.first)
        let permissions = permissionsCall.attributes[.posixPermissions] as? NSNumber
        #expect(permissions?.intValue == 0o755)
    }

    // MARK: - Non-writable destination (sudo fallback)

    @Test
    func test_updateIfNeeded_nonWritableDestination_usesSudo() async throws {
        let (sut, fileManager, subprocess, sudo) = makeSUT(subprocessExitCodes: [0], sudoExitCode: 0)
        fileManager.stubbedVersionFileContent = "1.0.0"
        fileManager.stubbedIsWritable = false

        try await sut.updateIfNeeded(currentVersion: "0.0.1")

        // Only unzip via subprocessRunner; sudo uses the dedicated SudoInstaller
        #expect(subprocess.recordedArguments.count == 1)
        #expect(subprocess.recordedArguments[0].first == "unzip")
        #expect(sudo.calls.count == 1)
        // No direct moveItem call
        #expect(fileManager.movedItems.isEmpty)
    }

    // MARK: - Download failure

    @Test
    func test_updateIfNeeded_downloadError_propagates() async throws {
        struct DownloadError: Error {}
        let (sut, fileManager, _, _) = makeSUT(fileDownloaderResult: .error(DownloadError()))
        fileManager.stubbedVersionFileContent = "1.0.0"

        await #expect(throws: (any Error).self) {
            try await sut.updateIfNeeded(currentVersion: "0.0.1")
        }
    }

    // MARK: - Extraction failure

    @Test
    func test_updateIfNeeded_extractionFails_throws() async throws {
        let (sut, fileManager, _, _) = makeSUT(subprocessExitCodes: [1])
        fileManager.stubbedVersionFileContent = "1.0.0"

        await #expect(throws: SelfUpdater.SelfUpdaterError.extractionFailed(1)) {
            try await sut.updateIfNeeded(currentVersion: "0.0.1")
        }
    }

    // MARK: - Sudo failure

    @Test
    func test_updateIfNeeded_sudoFails_throws() async throws {
        let (sut, fileManager, _, _) = makeSUT(subprocessExitCodes: [0], sudoExitCode: 1)
        fileManager.stubbedVersionFileContent = "1.0.0"
        fileManager.stubbedIsWritable = false

        await #expect(throws: (any Error).self) {
            try await sut.updateIfNeeded(currentVersion: "0.0.1")
        }
    }

    // MARK: - Binary not found

    @Test
    func test_updateIfNeeded_binaryNotFoundInArchive_throws() async throws {
        let (sut, fileManager, _, _) = makeSUT(subprocessExitCodes: [0])
        fileManager.stubbedVersionFileContent = "1.0.0"
        fileManager.stubbedBinaryExists = false

        await #expect(throws: SelfUpdater.SelfUpdaterError.binaryNotFound) {
            try await sut.updateIfNeeded(currentVersion: "0.0.1")
        }
    }

    @Test
    func test_updateIfNeeded_binaryNotFoundInArchive_cleansUpTempDir() async throws {
        let (sut, fileManager, _, _) = makeSUT(subprocessExitCodes: [0])
        fileManager.stubbedVersionFileContent = "1.0.0"
        fileManager.stubbedBinaryExists = false

        await #expect(throws: (any Error).self) {
            try await sut.updateIfNeeded(currentVersion: "0.0.1")
        }

        #expect(fileManager.removedItems.count == 1)
    }

    // MARK: - Writable destination move failure (sudo fallback)

    @Test
    func test_updateIfNeeded_writableDestinationMoveItemFails_fallsBackToSudo() async throws {
        struct MoveError: Error {}
        let (sut, fileManager, _, sudo) = makeSUT(subprocessExitCodes: [0], sudoExitCode: 0)
        fileManager.stubbedVersionFileContent = "1.0.0"
        fileManager.stubbedIsWritable = true
        fileManager.stubbedMoveItemError = MoveError()

        try await sut.updateIfNeeded(currentVersion: "0.0.1")

        #expect(sudo.calls.count == 1)
    }

    // MARK: - Public init

    @Test
    func test_publicInit_skipsUpdateWhenNoVersionFile() async throws {
        let fileManager = SelfUpdaterFileManagerMock()
        fileManager.stubbedVersionFileContent = nil
        let sut = SelfUpdater(fileManager: fileManager, printer: PrinterMock())

        // Should return early without throwing — exercises the public init code path.
        try await sut.updateIfNeeded(currentVersion: "1.0.0")
    }

    // MARK: - Error descriptions

    @Test
    func test_selfUpdaterError_errorDescriptions_areNonNilAndNonEmpty() {
        let errors: [SelfUpdater.SelfUpdaterError] = [
            .invalidVersionFormat("bad-version"),
            .cannotResolveExecutablePath,
            .extractionFailed(1),
            .binaryNotFound,
            .installFailed("/usr/local/bin/luca")
        ]
        for error in errors {
            #expect(error.errorDescription != nil)
            #expect(error.errorDescription?.isEmpty == false)
        }
    }

    // MARK: - Cleanup

    @Test
    func test_updateIfNeeded_cleansUpTempDirAfterSuccess() async throws {
        let (sut, fileManager, _, _) = makeSUT(subprocessExitCodes: [0])
        fileManager.stubbedVersionFileContent = "1.0.0"
        fileManager.stubbedIsWritable = true

        try await sut.updateIfNeeded(currentVersion: "0.0.1")

        #expect(fileManager.removedItems.count == 1)
    }

    @Test
    func test_updateIfNeeded_cleansUpTempDirAfterExtractionFailure() async throws {
        let (sut, fileManager, _, _) = makeSUT(subprocessExitCodes: [1])
        fileManager.stubbedVersionFileContent = "1.0.0"

        await #expect(throws: (any Error).self) {
            try await sut.updateIfNeeded(currentVersion: "0.0.1")
        }

        #expect(fileManager.removedItems.count == 1)
    }
}
