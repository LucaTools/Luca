//  SkillLatestVersionResolver.swift

import Foundation
import LucaFoundation

/// Resolves `Skill.latestVersionKeyword` ("latest") to a concrete commit SHA via `git ls-remote`.
///
/// The resolved SHA is a normal 40-character commit SHA from the caller's perspective — it flows
/// into ``SkillSet/version`` exactly like any hand-typed SHA in a Lucafile, so every downstream
/// consumer (cache path, symlink target, `git checkout`) requires no special-casing for `latest`.
struct SkillLatestVersionResolver: SkillLatestVersionResolving {

    // MARK: - Error

    enum SkillLatestVersionResolverError: Error, LocalizedError, Equatable {
        /// The git executable was not found at the expected path.
        case gitNotFound
        /// `git ls-remote` exited with a non-zero status.
        case lsRemoteFailed(repository: String, exitCode: Int32)
        /// `git ls-remote` succeeded but its output did not contain a parseable commit SHA for HEAD.
        case headRefNotFound(repository: String)

        var errorDescription: String? {
            switch self {
            case .gitNotFound:
                return "Could not find git at /usr/bin/git. Please install git (e.g. Xcode Command Line Tools on macOS)."
            case .lsRemoteFailed(let repo, let exitCode):
                return "Failed to resolve the latest commit for '\(repo)' (git ls-remote exited with code \(exitCode)). Ensure the repository URL is correct and reachable."
            case .headRefNotFound(let repo):
                return "Could not determine the default branch HEAD commit for '\(repo)'."
            }
        }
    }

    // MARK: - Properties

    private static let gitExecutableURL = URL(fileURLWithPath: "/usr/bin/git")

    private let outputRunner: SubprocessOutputRunning

    // MARK: - Init

    init(outputRunner: SubprocessOutputRunning = SubprocessOutputRunner()) {
        self.outputRunner = outputRunner
    }

    // MARK: - SkillLatestVersionResolving

    func resolveLatestVersion(repository: String) async throws -> String {
        guard FileManager.default.fileExists(atPath: Self.gitExecutableURL.path) else {
            throw SkillLatestVersionResolverError.gitNotFound
        }

        let url = GitRepositoryURLNormalizer.cloneURL(for: repository)
        let (exitCode, output) = try await outputRunner.run(
            executableURL: Self.gitExecutableURL,
            arguments: ["ls-remote", "--quiet", url, "HEAD"],
            environment: ["GIT_TERMINAL_PROMPT": "0"]
        )

        guard exitCode == 0 else {
            throw SkillLatestVersionResolverError.lsRemoteFailed(repository: repository, exitCode: exitCode)
        }

        guard
            let firstLine = output.split(separator: "\n").first,
            let sha = firstLine.split(separator: "\t").first.map(String.init),
            sha.count == 40,
            sha.allSatisfy({ $0.isHexDigit })
        else {
            throw SkillLatestVersionResolverError.headRefNotFound(repository: repository)
        }

        return sha
    }
}
