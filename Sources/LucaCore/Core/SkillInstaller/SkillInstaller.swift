//  SkillInstaller.swift

import Foundation

/// Installs agentic skills by delegating to `npx skills add`.
///
/// `SkillInstaller` builds the `npx skills add <repository> --yes [--skill name...] [--agent name...]`
/// command and runs it via a ``SubprocessRunning`` instance.
struct SkillInstaller: SkillInstalling {

    enum SkillInstallerError: Error, LocalizedError, Equatable {
        /// `npx` was not found in the current environment.
        case npxNotAvailable
        /// The `npx skills add` command exited with a non-zero status.
        case installationFailed(String, Int32)

        var errorDescription: String? {
            switch self {
            case .npxNotAvailable:
                return "To install skills, Luca is currently relying on npx which is not available. Please install Node.js and npm to install skills."
            case .installationFailed(let name, let exitCode):
                return "Failed to install skill '\(name)' (exit code \(exitCode))."
            }
        }
    }

    private let subprocessRunner: SubprocessRunning
    
    init(subprocessRunner: SubprocessRunning = SubprocessRunner()) {
        self.subprocessRunner = subprocessRunner
    }

    /// Installs the given skill via `npx skills add`.
    ///
    /// - Parameters:
    ///   - skillSet: The ``SkillSet`` to install.
    ///   - agents: Agent identifiers passed as `--agent` flags. `nil` installs for all supported agents.
    func install(skillSet: SkillSet, agents: [String]?) async throws {
        var arguments = ["npx", "skills", "add", skillSet.repository, "--yes"]
        for skill in skillSet.skills {
            arguments += ["--skill", skill]
        }
        if let agents {
            for agent in agents {
                arguments += ["--agent", agent]
            }
        }

        let envURL = URL(fileURLWithPath: "/usr/bin/env")

        // Verify npx is available
        let whichStatus = try await subprocessRunner.run(
            executableURL: envURL,
            arguments: ["which", "npx"]
        )
        guard whichStatus == 0 else {
            throw SkillInstallerError.npxNotAvailable
        }

        let status = try await subprocessRunner.run(executableURL: envURL, arguments: arguments)
        guard status == 0 else {
            throw SkillInstallerError.installationFailed(skillSet.repository, status)
        }
    }
}
