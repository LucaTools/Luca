//  SelfUpdater.swift

import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

/// Replaces the Luca binary with a newer version when `.luca-version` differs
/// from the running binary's built-in version constant.
///
/// ## Update flow
///
/// 1. Read `.luca-version` from the current working directory.
/// 2. Compare with `currentVersion`; skip if identical or file is absent.
/// 3. Validate the target version string as a semver triple (`x.y.z`).
/// 4. Download the platform ZIP from the GitHub releases page.
/// 5. Extract the ZIP to a unique temp directory using `unzip`.
/// 6. Set executable permissions (`0o755`) on the extracted binary.
/// 7. Replace the running binary via `moveItem`; fall back to
///    `sudo install -m 755` if the destination is not writable.
/// 8. Clean up the temp directory.
///
/// All errors are propagated to the caller; the CLI entry point catches them
/// and prints a non-fatal warning so the requested command still runs.
///
/// ## Topics
///
/// ### Updating
/// - ``updateIfNeeded(currentVersion:)``
public struct SelfUpdater: SelfUpdating {

    // MARK: - Error

    enum SelfUpdaterError: Error, LocalizedError, Equatable {
        case invalidVersionFormat(String)
        case cannotResolveExecutablePath
        case extractionFailed(Int32)
        case binaryNotFound
        case installFailed(String)

        var errorDescription: String? {
            switch self {
            case .invalidVersionFormat(let v):
                return "Invalid version format '\(v)' in .luca-version. Expected semver (e.g. 1.2.3)."
            case .cannotResolveExecutablePath:
                return "Cannot resolve the path of the running Luca executable."
            case .extractionFailed(let code):
                return "Extraction failed with exit code \(code)."
            case .binaryNotFound:
                return "Extracted archive does not contain the expected 'Luca' binary."
            case .installFailed(let path):
                return "Failed to install updated binary to '\(path)'. Try running the install script manually."
            }
        }
    }

    // MARK: - Properties

    private let fileManager: SelfUpdaterFileManaging
    private let fileDownloader: FileDownloading
    private let subprocessRunner: SubprocessRunning
    private let sudoInstaller: SudoInstalling
    private let printer: Printing

    // MARK: - Init

    /// Creates a `SelfUpdater` with production dependencies.
    ///
    /// - Parameters:
    ///   - fileManager: File system interface.
    ///   - printer: Outputs warnings and status messages.
    public init(fileManager: SelfUpdaterFileManaging, printer: Printing) {
        self.fileManager = fileManager
        self.fileDownloader = FileDownloader()
        self.subprocessRunner = SubprocessRunner()
        self.sudoInstaller = SudoInstaller()
        self.printer = printer
    }

    /// Creates a `SelfUpdater` with injectable dependencies for testing.
    init(
        fileManager: SelfUpdaterFileManaging,
        fileDownloader: FileDownloading,
        subprocessRunner: SubprocessRunning,
        sudoInstaller: SudoInstalling,
        printer: Printing
    ) {
        self.fileManager = fileManager
        self.fileDownloader = fileDownloader
        self.subprocessRunner = subprocessRunner
        self.sudoInstaller = sudoInstaller
        self.printer = printer
    }

    // MARK: - SelfUpdating

    /// Checks `.luca-version` in the current directory and installs the required version if needed.
    ///
    /// - Parameter currentVersion: The version string of the running binary.
    public func updateIfNeeded(currentVersion: String) async throws {
        let versionFilePath = fileManager.currentDirectoryPath + "/.luca-version"

        guard fileManager.fileExists(atPath: versionFilePath) else { return }

        guard
            let rawContent = fileManager.contentsOfFile(atPath: versionFilePath),
            !rawContent.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        else { return }

        let targetVersion = rawContent.trimmingCharacters(in: .whitespacesAndNewlines)
        guard targetVersion != currentVersion else { return }

        try validate(version: targetVersion)

        printer.printFormatted("\(.raw("🔄 Updating Luca \(currentVersion) → \(targetVersion)..."))")

        let (tempZipURL, _) = try await fileDownloader.download(from: downloadURL(for: targetVersion))

        let tempExtractDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("luca-update-\(UUID().uuidString)")

        try fileManager.createDirectory(at: tempExtractDir, withIntermediateDirectories: true)

        let extractExitCode = try await subprocessRunner.run(
            executableURL: URL(fileURLWithPath: "/usr/bin/env"),
            arguments: ["unzip", "-q", "-o", tempZipURL.path, "-d", tempExtractDir.path]
        )
        guard extractExitCode == 0 else {
            try? fileManager.removeItem(at: tempExtractDir)
            throw SelfUpdaterError.extractionFailed(extractExitCode)
        }

        let candidateNames = ["luca", "Luca"]
        guard let extractedBinary = candidateNames
            .map({ tempExtractDir.appendingPathComponent($0) })
            .first(where: { fileManager.fileExists(atPath: $0.path) })
        else {
            try? fileManager.removeItem(at: tempExtractDir)
            throw SelfUpdaterError.binaryNotFound
        }

        try fileManager.setAttributes([.posixPermissions: NSNumber(value: 0o755)], ofItemAtPath: extractedBinary.path)

        guard let arg0 = ProcessInfo.processInfo.arguments.first else {
            try? fileManager.removeItem(at: tempExtractDir)
            throw SelfUpdaterError.cannotResolveExecutablePath
        }
        let installDir = URL(fileURLWithPath: arg0).standardized.resolvingSymlinksInPath()
            .deletingLastPathComponent()
        let destination = installDir.appendingPathComponent("luca")

        try await install(binaryURL: extractedBinary, to: destination)

        try? fileManager.removeItem(at: tempExtractDir)

        printer.printFormatted("\(.primary("✅ Luca updated to \(targetVersion). The new version will be used on the next run."))")
    }

    // MARK: - Private

    private func validate(version: String) throws {
        guard version.range(of: #"^\d+\.\d+\.\d+$"#, options: .regularExpression) != nil else {
            throw SelfUpdaterError.invalidVersionFormat(version)
        }
    }

    private func downloadURL(for version: String) -> URL {
        #if os(Linux)
        let asset = "Luca-Linux.zip"
        #else
        let asset = "Luca-macOS.zip"
        #endif
        // Force-unwrap is safe: the URL is built from compile-time constants
        // plus a semver-validated version string that cannot contain illegal URL characters.
        return URL(string: "https://github.com/LucaTools/Luca/releases/download/\(version)/\(asset)")!
    }

    private func install(binaryURL: URL, to destination: URL) async throws {
        if fileManager.isWritableFile(atPath: destination.path) {
            do {
                try fileManager.moveItem(at: binaryURL, to: destination)
                return
            } catch {
                // Fall through to sudo path on any move failure
            }
        }

        let exitCode = try await sudoInstaller.install(from: binaryURL, to: destination)
        guard exitCode == 0 else {
            throw SelfUpdaterError.installFailed(destination.path)
        }
    }
}
