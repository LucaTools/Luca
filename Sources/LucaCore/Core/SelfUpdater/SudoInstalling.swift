//  SudoInstalling.swift

import Foundation

/// Installs a file to a privileged location using `sudo install`.
///
/// Implementations must ensure `sudo` can properly open `/dev/tty` and call
/// `tcsetattr` to disable terminal echo when prompting for the password.
/// The recommended approach is `system()` rather than `Process`, because
/// `Process` launched from Swift's async runtime does not reliably establish
/// the controlling terminal for the child process.
protocol SudoInstalling {

    /// Installs `source` to `destination` using `sudo install -m 755`.
    ///
    /// - Parameters:
    ///   - source: Path of the file to install.
    ///   - destination: Target path (typically a privileged location such as `/usr/local/bin/luca`).
    /// - Returns: The `sudo` process termination status.
    func install(from source: URL, to destination: URL) async throws -> Int32
}
