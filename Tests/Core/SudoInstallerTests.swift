//  SudoInstallerTests.swift

import Foundation
import Testing
@testable import LucaCore
@testable import ManagerCore

struct SudoInstallerTests {

    // MARK: - Exit code extraction

    @Test
    func test_spawnAndWait_successfulCommand_returnsZero() throws {
        let code = try SudoInstaller.spawnAndWait(executable: "/usr/bin/true", arguments: [])
        #expect(code == 0)
    }

    @Test
    func test_spawnAndWait_failingCommand_returnsOne() throws {
        let code = try SudoInstaller.spawnAndWait(executable: "/usr/bin/false", arguments: [])
        #expect(code == 1)
    }

    @Test
    func test_spawnAndWait_specificExitCode_extractedCorrectly() throws {
        // Uses sh to exit with a known code, verifying the (waitStatus >> 8) & 0xFF extraction.
        let code = try SudoInstaller.spawnAndWait(executable: "/bin/sh", arguments: ["-c", "exit 42"])
        #expect(code == 42)
    }

    // MARK: - Argument passing

    @Test
    func test_spawnAndWait_argumentsPassedWithoutShellInterpretation() throws {
        // A path containing spaces must be passed as a single argument, not split by the shell.
        let dir = FileManager.default.temporaryDirectory
            .appendingPathComponent("sudo installer test \(UUID().uuidString)")
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: dir) }

        let code = try SudoInstaller.spawnAndWait(executable: "/bin/ls", arguments: [dir.path])
        #expect(code == 0)
    }

    // MARK: - Spawn failure

    @Test
    func test_spawnAndWait_nonExistentExecutable_throwsPOSIXError() {
        #expect(throws: (any Error).self) {
            try SudoInstaller.spawnAndWait(executable: "/nonexistent/executable", arguments: [])
        }
    }

    // MARK: - install(from:to:) async interface

    @Test
    func test_install_successfulCommand_returnsZero() async throws {
        let sut = SudoInstaller(executablePath: "/usr/bin/true")
        let code = try await sut.install(
            from: URL(fileURLWithPath: "/tmp/src"),
            to: URL(fileURLWithPath: "/tmp/dst")
        )
        #expect(code == 0)
    }

    @Test
    func test_install_failingCommand_returnsNonZero() async throws {
        let sut = SudoInstaller(executablePath: "/usr/bin/false")
        let code = try await sut.install(
            from: URL(fileURLWithPath: "/tmp/src"),
            to: URL(fileURLWithPath: "/tmp/dst")
        )
        #expect(code != 0)
    }

    @Test
    func test_install_nonExistentExecutable_throws() async throws {
        let sut = SudoInstaller(executablePath: "/nonexistent/executable")
        await #expect(throws: (any Error).self) {
            try await sut.install(
                from: URL(fileURLWithPath: "/tmp/src"),
                to: URL(fileURLWithPath: "/tmp/dst")
            )
        }
    }
}
