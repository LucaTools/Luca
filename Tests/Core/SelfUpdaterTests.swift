//  SelfUpdaterTests.swift

import Foundation
import Testing
@testable import LucaFoundation
@testable import ManagerCore

struct SelfUpdaterTests {

    // MARK: - Helpers

    private func makeSUT(
        fileManager: SelfUpdaterFileManagerMock = SelfUpdaterFileManagerMock(),
        fileDownloaderResult: FileDownloadingMock.Result = .success(
            FileManager.default.temporaryDirectory.appendingPathComponent("test-luca.zip")
        ),
        subprocessExitCodes: [Int32] = [0],
        sudoExitCode: Int32 = 0,
        dataDownloader: DataDownloaderMock = DataDownloaderMock(result: .statusCode(500))
    ) -> (sut: SelfUpdater, fileManager: SelfUpdaterFileManagerMock, subprocess: SubprocessRunnerMock, sudo: SudoInstallerMock) {
        let fileDownloader = FileDownloadingMock(result: fileDownloaderResult)
        let subprocess = SubprocessRunnerMock()
        subprocess.exitCodes = subprocessExitCodes
        let sudo = SudoInstallerMock()
        sudo.exitCode = sudoExitCode
        let sut = SelfUpdater(
            fileManager: fileManager,
            fileDownloader: fileDownloader,
            dataDownloader: dataDownloader,
            subprocessRunner: subprocess,
            sudoInstaller: sudo,
            printer: PrinterMock()
        )
        return (sut, fileManager, subprocess, sudo)
    }

    private func latestReleaseData(tagName: String) -> Data {
        Data(#"{"tag_name": "\#(tagName)"}"#.utf8)
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

    @Test
    func test_updateIfNeeded_versionNotFound_throwsVersionNotFound() async throws {
        let (sut, fileManager, _, _) = makeSUT(
            dataDownloader: DataDownloaderMock(result: .statusCode(404))
        )
        fileManager.stubbedVersionFileContent = "1.0.0"

        await #expect(throws: SelfUpdater.SelfUpdaterError.versionNotFound("1.0.0")) {
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
            .installFailed("/usr/local/bin/luca"),
            .versionNotFound("1.0.0")
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

    // MARK: - updateToLatest — already up to date

    @Test
    func test_updateToLatest_alreadyUpToDate_skipsInstall() async throws {
        let data = latestReleaseData(tagName: "1.0.0")
        let (sut, _, subprocess, _) = makeSUT(
            subprocessExitCodes: [0],
            dataDownloader: DataDownloaderMock(result: .rawData(data, 200))
        )

        try await sut.updateToLatest(currentVersion: "1.0.0")

        #expect(subprocess.recordedArguments.isEmpty)
    }

    @Test
    func test_updateToLatest_tagWithVPrefix_normalised() async throws {
        let data = latestReleaseData(tagName: "v1.0.0")
        let (sut, _, subprocess, _) = makeSUT(
            subprocessExitCodes: [0],
            dataDownloader: DataDownloaderMock(result: .rawData(data, 200))
        )

        try await sut.updateToLatest(currentVersion: "1.0.0")

        // "v1.0.0" normalised to "1.0.0" == currentVersion → no install
        #expect(subprocess.recordedArguments.isEmpty)
    }

    // MARK: - updateToLatest — new version available

    @Test
    func test_updateToLatest_newVersionAvailable_installs() async throws {
        let data = latestReleaseData(tagName: "2.0.0")
        let (sut, fileManager, subprocess, _) = makeSUT(
            subprocessExitCodes: [0],
            dataDownloader: DataDownloaderMock(result: .rawData(data, 200))
        )
        fileManager.stubbedIsWritable = true

        try await sut.updateToLatest(currentVersion: "1.0.0")

        #expect(subprocess.recordedArguments.count == 1)
        #expect(subprocess.recordedArguments[0].first == "unzip")
        #expect(fileManager.movedItems.count == 1)
    }

    @Test
    func test_updateToLatest_tagWithVPrefix_newVersion_installs() async throws {
        let data = latestReleaseData(tagName: "v2.0.0")
        let (sut, fileManager, subprocess, _) = makeSUT(
            subprocessExitCodes: [0],
            dataDownloader: DataDownloaderMock(result: .rawData(data, 200))
        )
        fileManager.stubbedIsWritable = true

        try await sut.updateToLatest(currentVersion: "1.0.0")

        #expect(subprocess.recordedArguments.count == 1)
        #expect(fileManager.movedItems.count == 1)
    }

    // MARK: - updateToLatest — API failures

    @Test
    func test_updateToLatest_apiFetchFails_throwsLatestVersionFetchFailed() async throws {
        let (sut, _, _, _) = makeSUT(dataDownloader: DataDownloaderMock(result: .statusCode(404)))

        await #expect(throws: SelfUpdater.SelfUpdaterError.latestVersionFetchFailed(404)) {
            try await sut.updateToLatest(currentVersion: "1.0.0")
        }
    }

    @Test
    func test_updateToLatest_networkError_propagates() async throws {
        struct NetworkError: Error {}
        let (sut, _, _, _) = makeSUT(dataDownloader: DataDownloaderMock(result: .error(NetworkError())))

        await #expect(throws: (any Error).self) {
            try await sut.updateToLatest(currentVersion: "1.0.0")
        }
    }

    // MARK: - Script refresh

    @Test
    func test_updateIfNeeded_refreshesScripts() async throws {
        let scriptContent = "#!/bin/sh\necho 'script'"
        let (sut, fileManager, _, _) = makeSUT(
            subprocessExitCodes: [0],
            dataDownloader: DataDownloaderMock(result: .rawData(Data(scriptContent.utf8), 200))
        )
        fileManager.stubbedVersionFileContent = "1.0.0"
        fileManager.stubbedIsWritable = true

        try await sut.updateIfNeeded(currentVersion: "0.0.1")

        let writtenNames = fileManager.writtenStrings.map(\.url.lastPathComponent)
        #expect(writtenNames.contains("post-checkout"))
        #expect(writtenNames.contains("shell_hook.sh"))
    }

    @Test
    func test_updateIfNeeded_scriptRefreshFailure_doesNotFailUpdate() async throws {
        // Default dataDownloader returns .statusCode(500), so script refresh is skipped.
        let (sut, fileManager, _, _) = makeSUT(subprocessExitCodes: [0])
        fileManager.stubbedVersionFileContent = "1.0.0"
        fileManager.stubbedIsWritable = true

        try await sut.updateIfNeeded(currentVersion: "0.0.1")

        // Binary update still succeeded
        #expect(fileManager.movedItems.count == 1)
        // No scripts written due to non-200 response
        #expect(fileManager.writtenStrings.isEmpty)
    }

    @Test
    func test_updateToLatest_alreadyUpToDate_stillRefreshesScripts() async throws {
        let data = latestReleaseData(tagName: "1.0.0")
        // Mock returns release JSON for first call but same for script downloads;
        // the important thing is scripts are attempted (written strings populated).
        let (sut, fileManager, _, _) = makeSUT(
            subprocessExitCodes: [0],
            dataDownloader: DataDownloaderMock(result: .rawData(data, 200))
        )

        try await sut.updateToLatest(currentVersion: "1.0.0")

        // Binary was already up to date — no install
        #expect(fileManager.movedItems.isEmpty)
        // Scripts still refreshed
        let writtenNames = fileManager.writtenStrings.map(\.url.lastPathComponent)
        #expect(writtenNames.contains("post-checkout"))
        #expect(writtenNames.contains("shell_hook.sh"))
    }

    // MARK: - updateToLatest — .luca-version sync

    @Test
    func test_updateToLatest_versionFileExists_updatesVersionFile() async throws {
        let data = latestReleaseData(tagName: "2.0.0")
        let (sut, fileManager, _, _) = makeSUT(
            subprocessExitCodes: [0],
            dataDownloader: DataDownloaderMock(result: .rawData(data, 200))
        )
        fileManager.stubbedVersionFileContent = "1.0.0"
        fileManager.stubbedIsWritable = true

        try await sut.updateToLatest(currentVersion: "1.0.0")

        let versionFileWrites = fileManager.writtenStrings.filter { $0.url.lastPathComponent == ".luca-version" }
        #expect(versionFileWrites.count == 1)
        #expect(versionFileWrites.first?.content == "2.0.0\n")
    }

    @Test
    func test_updateToLatest_noVersionFile_doesNotCreateOne() async throws {
        let data = latestReleaseData(tagName: "2.0.0")
        let (sut, fileManager, _, _) = makeSUT(
            subprocessExitCodes: [0],
            dataDownloader: DataDownloaderMock(result: .rawData(data, 200))
        )
        fileManager.stubbedVersionFileContent = nil
        fileManager.stubbedIsWritable = true

        try await sut.updateToLatest(currentVersion: "1.0.0")

        let versionFileWrites = fileManager.writtenStrings.filter { $0.url.lastPathComponent == ".luca-version" }
        #expect(versionFileWrites.isEmpty)
    }

    @Test
    func test_updateToLatest_alreadyUpToDate_doesNotWriteVersionFile() async throws {
        let data = latestReleaseData(tagName: "1.0.0")
        let (sut, fileManager, _, _) = makeSUT(
            subprocessExitCodes: [0],
            dataDownloader: DataDownloaderMock(result: .rawData(data, 200))
        )
        fileManager.stubbedVersionFileContent = "1.0.0"

        try await sut.updateToLatest(currentVersion: "1.0.0")

        let versionFileWrites = fileManager.writtenStrings.filter { $0.url.lastPathComponent == ".luca-version" }
        #expect(versionFileWrites.isEmpty)
    }
}
