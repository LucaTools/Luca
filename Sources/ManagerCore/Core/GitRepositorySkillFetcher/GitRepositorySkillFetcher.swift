//  GitRepositorySkillFetcher.swift

import Foundation
import LucaFoundation

// MARK: - Error

/// Errors thrown by ``GitRepositorySkillFetcher``.
enum GitRepositorySkillFetcherError: Error, LocalizedError, Equatable {
    /// The git executable was not found at the expected path.
    case gitNotFound
    /// The `git clone` command exited with a non-zero status.
    case cloneFailed(repository: String, exitCode: Int32)
    /// The `git checkout` command for a commit SHA exited with a non-zero status.
    case checkoutFailed(repository: String, ref: String, exitCode: Int32)
    /// A skill file could not be read from the cloned repository.
    case fileReadFailed(path: String)

    var errorDescription: String? {
        switch self {
        case .gitNotFound:
            return "Could not find git at /usr/bin/git. Please install git (e.g. Xcode Command Line Tools on macOS)."
        case .cloneFailed(let repo, let exitCode):
            return "Failed to clone '\(repo)' (exit code \(exitCode)). Ensure the URL is correct and that you have access — for SSH repositories, verify that your SSH key is loaded and authorised for this host."
        case .checkoutFailed(let repo, let ref, let exitCode):
            return "Failed to check out '\(ref)' in '\(repo)' (exit code \(exitCode)). Ensure the commit SHA or tag exists in the repository."
        case .fileReadFailed(let path):
            return "Failed to read '\(path)' from the cloned repository."
        }
    }
}

// MARK: - Implementation

/// Fetches skill files by performing a shallow `git clone` of the repository.
///
/// Using the system `git` binary means any authentication already configured on the host
/// — SSH keys, SSH agents, credential helpers, `.netrc` — is transparently available.
/// This makes the fetcher suitable for private repositories and GitHub Enterprise Server
/// instances without requiring any additional token configuration.
///
/// Clones are cached by repository URL within a single fetcher instance, so listing paths
/// and downloading files for the same repository triggers only one `git clone`.
actor GitRepositorySkillFetcher: SkillRepositoryFetching {

    // MARK: - Constants

    private static let gitExecutableURL = URL(fileURLWithPath: "/usr/bin/git")

    /// File names that are never included, regardless of location.
    private static let excludedFileNames: Set<String> = ["metadata.json"]

    /// Directory names whose contents are never included.
    private static let excludedDirectories: Set<String> = [".git", "__pycache__", "__pypackages__"]

    // MARK: - Properties

    private let subprocessRunner: SubprocessRunning
    /// Maps `"repository@ref"` (or `"repository@HEAD"` when no ref) → local clone directory.
    private var cloneCache: [String: URL] = [:]

    // MARK: - Init

    init(subprocessRunner: SubprocessRunning = SubprocessRunner()) {
        self.subprocessRunner = subprocessRunner
    }

    deinit {
        for (_, url) in cloneCache {
            try? FileManager.default.removeItem(at: url)
        }
    }

    // MARK: - SkillRepositoryFetching

    func skillPaths(repository: String, ref: String?) async throws -> [String] {
        let cloneDir = try await clone(repository, ref: ref)
        return enumerateSkillPaths(in: cloneDir)
    }

    func downloadSkill(repository: String, path: String, ref: String?) async throws -> Data {
        let cloneDir = try await clone(repository, ref: ref)
        let baseDir = cloneDir.resolvingSymlinksInPath()
        let fileURL = baseDir.appendingPathComponent(path)

        // A malicious skill repository must not be able to make Luca read files outside the clone
        // (e.g. a symlink pointing at ~/.ssh/id_rsa). Reject the read if the final component is a
        // symbolic link, or if resolving the path escapes the clone directory.
        let resourceValues = try? fileURL.resourceValues(forKeys: [.isSymbolicLinkKey])
        if resourceValues?.isSymbolicLink == true {
            throw GitRepositorySkillFetcherError.fileReadFailed(path: path)
        }
        let resolvedPath = fileURL.resolvingSymlinksInPath().standardizedFileURL.path
        let basePath = baseDir.standardizedFileURL.path
        guard resolvedPath == basePath || resolvedPath.hasPrefix(basePath + "/") else {
            throw GitRepositorySkillFetcherError.fileReadFailed(path: path)
        }

        do {
            return try Data(contentsOf: fileURL)
        } catch {
            throw GitRepositorySkillFetcherError.fileReadFailed(path: path)
        }
    }

    // MARK: - Private

    private func clone(_ repository: String, ref: String?) async throws -> URL {
        let cacheKey = "\(repository)@\(ref ?? "HEAD")"
        if let cached = cloneCache[cacheKey] {
            return cached
        }

        guard FileManager.default.fileExists(atPath: Self.gitExecutableURL.path) else {
            throw GitRepositorySkillFetcherError.gitNotFound
        }

        let tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
        let gitURL = GitRepositoryURLNormalizer.cloneURL(for: repository)

        if let ref, isCommitSHA(ref) {
            let cloneExitCode = try await subprocessRunner.run(
                executableURL: Self.gitExecutableURL,
                arguments: ["clone", "--quiet", gitURL, tempDir.path],
                environment: ["GIT_TERMINAL_PROMPT": "0"]
            )
            guard cloneExitCode == 0 else {
                throw GitRepositorySkillFetcherError.cloneFailed(repository: repository, exitCode: cloneExitCode)
            }
            let checkoutExitCode = try await subprocessRunner.run(
                executableURL: Self.gitExecutableURL,
                arguments: ["-C", tempDir.path, "checkout", ref],
                environment: ["GIT_TERMINAL_PROMPT": "0"]
            )
            guard checkoutExitCode == 0 else {
                throw GitRepositorySkillFetcherError.checkoutFailed(repository: repository, ref: ref, exitCode: checkoutExitCode)
            }
        } else {
            var arguments = ["clone", "--quiet", "--depth", "1"]
            if let ref {
                arguments += ["--branch", ref]
            }
            arguments += [gitURL, tempDir.path]

            let exitCode = try await subprocessRunner.run(
                executableURL: Self.gitExecutableURL,
                arguments: arguments,
                environment: ["GIT_TERMINAL_PROMPT": "0"]
            )
            guard exitCode == 0 else {
                throw GitRepositorySkillFetcherError.cloneFailed(repository: repository, exitCode: exitCode)
            }
        }

        cloneCache[cacheKey] = tempDir
        return tempDir
    }

    /// Returns `true` when `ref` looks like a commit SHA (7–40 hexadecimal characters).
    private func isCommitSHA(_ ref: String) -> Bool {
        ref.count >= 7 && ref.count <= 40 && ref.allSatisfy(\.isHexDigit)
    }

    /// Walks the cloned directory and returns paths of all skill-related files.
    ///
    /// A file is included when it is either a `SKILL.md` or lives inside a directory that
    /// contains a `SKILL.md`, excluding files and directories on the exclusion lists.
    private func enumerateSkillPaths(in directory: URL) -> [String] {
        // Resolve symlinks on both sides so that relative-path computation is consistent
        // even when the system temp directory involves a symlink (e.g. /tmp → /private/tmp).
        let resolvedBase = directory.resolvingSymlinksInPath()
        guard let enumerator = FileManager.default.enumerator(
            at: resolvedBase,
            includingPropertiesForKeys: [.isDirectoryKey, .isSymbolicLinkKey],
            options: [.skipsHiddenFiles]
        ) else {
            return []
        }

        let baseComponents = resolvedBase.pathComponents
        var allPaths: [String] = []

        while let fileURL = enumerator.nextObject() as? URL {
            let resourceValues = try? fileURL.resourceValues(forKeys: [.isDirectoryKey, .isSymbolicLinkKey])
            let isDir = resourceValues?.isDirectory ?? false
            if isDir { continue }
            
            // Skip all symbolic links. Following them risks reading files outside the cloned
            // repository (e.g. a link pointing at ~/.ssh), and the GitHub tree client excludes
            // symlinks too, so this keeps both fetchers consistent.
            let isSymlink = resourceValues?.isSymbolicLink ?? false
            if isSymlink { continue }

            let fileComponents = fileURL.resolvingSymlinksInPath().pathComponents
            let relativePath = fileComponents.dropFirst(baseComponents.count).joined(separator: "/")
            let components = relativePath.components(separatedBy: "/")

            if let fileName = components.last, Self.excludedFileNames.contains(fileName) { continue }
            if components.dropLast().contains(where: { Self.excludedDirectories.contains($0) }) { continue }

            allPaths.append(relativePath)
        }

        // Include only SKILL.md files and files inside a directory that contains a SKILL.md.
        let skillMdPaths = allPaths.filter { $0.hasSuffix("SKILL.md") }
        let skillDirectories: Set<String> = Set(
            skillMdPaths
                .filter { $0 != "SKILL.md" }
                .map { $0.components(separatedBy: "/").dropLast().joined(separator: "/") }
        )

        return allPaths.filter { path in
            path.hasSuffix("SKILL.md")
                || skillDirectories.contains(where: { path.hasPrefix($0 + "/") })
        }
    }
}
