//  SudoInstaller.swift

import Foundation
#if canImport(Darwin)
import Darwin
#elseif canImport(Glibc)
import Glibc
#endif

/// Installs a file to a privileged location by running `sudo install -m 755`.
///
/// `posix_spawn` is used instead of `Process` (NSTask) because `Process` on macOS
/// may set `POSIX_SPAWN_SETSID` internally, which creates a new session for the
/// child and strips it of its controlling terminal. Without a controlling terminal,
/// `sudo` cannot open `/dev/tty`, cannot call `tcsetattr` to disable terminal echo,
/// and the typed password appears in clear text.
///
/// Calling `posix_spawn` directly without session-creation flags ensures the child
/// inherits the parent's session and controlling terminal, allowing `sudo` to handle
/// password prompting correctly.
struct SudoInstaller: SudoInstalling {

    // The path of the sudo executable. Overridable in tests to inject a benign binary.
    let executablePath: String

    init(executablePath: String = "/usr/bin/sudo") {
        self.executablePath = executablePath
    }

    /// Installs `source` to `destination` using `sudo install -m 755`.
    ///
    /// - Parameters:
    ///   - source: Path of the file to install.
    ///   - destination: Target path.
    /// - Returns: The `sudo` process exit code, or throws on spawn failure.
    func install(from source: URL, to destination: URL) async throws -> Int32 {
        let executable = executablePath
        return try await withCheckedThrowingContinuation { continuation in
            // Run on a dedicated POSIX thread: waitpid() blocks and must not
            // occupy the Swift cooperative thread pool.
            Thread.detachNewThread {
                do {
                    let exitCode = try Self.spawnAndWait(
                        executable: executable,
                        arguments: ["install", "-m", "755", source.path, destination.path]
                    )
                    continuation.resume(returning: exitCode)
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    // MARK: - Private

    static func spawnAndWait(executable: String, arguments: [String]) throws -> Int32 {
        // Build a null-terminated C argv array: [executable] + arguments + [nil].
        let allArgs = [executable] + arguments
        let cStrings = allArgs.map { strdup($0) }
        defer { cStrings.forEach { free($0) } }

        // strdup returns UnsafeMutablePointer<CChar>? — assign directly then append the nil sentinel.
        var argv: [UnsafeMutablePointer<CChar>?] = cStrings
        argv.append(nil)

        var pid: pid_t = 0
        let spawnResult = argv.withUnsafeMutableBufferPointer { ptr in
            posix_spawn(&pid, executable, nil, nil, ptr.baseAddress, environ)
        }

        guard spawnResult == 0 else {
            throw POSIXError(POSIXErrorCode(rawValue: spawnResult) ?? .EPERM)
        }

        var waitStatus: Int32 = 0
        waitpid(pid, &waitStatus, 0)
        // Extract the exit code via WEXITSTATUS logic: (waitStatus >> 8) & 0xFF.
        return (waitStatus >> 8) & 0xFF
    }
}
