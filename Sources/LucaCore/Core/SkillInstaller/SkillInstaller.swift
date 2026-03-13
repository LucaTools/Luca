//  SkillInstaller.swift

import Foundation

/// Installs agentic skills by delegating to `npx skills add`.
///
/// `SkillInstaller` builds the `npx skills add <repository> [--skill name...]`
/// command and runs it via a ``SubprocessRunning`` instance. It validates the
/// repository reference using ``SkillRepositoryResolver`` before invoking `npx`.
struct SkillInstaller: SkillInstalling {

    enum SkillInstallerError: Error, LocalizedError, Equatable {
        /// `npx` was not found in the current environment.
        case npxNotAvailable
        /// The `npx skills add` command exited with a non-zero status.
        case installationFailed(String, Int32)

        var errorDescription: String? {
            switch self {
            case .npxNotAvailable:
                return "npx is not available. Please install Node.js and npm to install skills."
            case .installationFailed(let name, let exitCode):
                return "Failed to install skill '\(name)' (exit code \(exitCode))."
            }
        }
    }

    private let subprocessRunner: SubprocessRunning
    private let resolver: SkillRepositoryResolver

    init(subprocessRunner: SubprocessRunning = SubprocessRunner()) {
        self.subprocessRunner = subprocessRunner
        self.resolver = SkillRepositoryResolver()
    }

    /// Installs the given skill via `npx skills add`.
    ///
    /// - Parameter skill: The ``Skill`` to install.
    func install(skill: Skill) async throws {
        let repository = try resolver.resolve(skill.repository)

        var arguments = ["npx", "skills", "add", repository]
        if let skillNames = skill.skills {
            for skillName in skillNames {
                arguments += ["--skill", skillName]
            }
        }

        let envURL = URL(fileURLWithPath: "/usr/bin/env")

        // Verify npx is available
        let whichStatus = try subprocessRunner.run(
            executableURL: envURL,
            arguments: ["which", "npx"]
        )
        guard whichStatus == 0 else {
            throw SkillInstallerError.npxNotAvailable
        }

        let status = try subprocessRunner.run(executableURL: envURL, arguments: arguments)
        guard status == 0 else {
            throw SkillInstallerError.installationFailed(skill.name, status)
        }
    }
}
