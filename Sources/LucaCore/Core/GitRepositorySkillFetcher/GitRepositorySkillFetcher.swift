//  GitRepositorySkillFetcher.swift

import Foundation

// MARK: - Error

/// Errors thrown by ``GitRepositorySkillFetcher``.
enum GitRepositorySkillFetcherError: Error, LocalizedError, Equatable {
    /// The git executable was not found at the expected path.
    case gitNotFound
    /// The `git clone` command exited with a non-zero status.
    case cloneFailed(repository: String, exitCode: Int32)
    /// A skill file could not be read from the cloned repository.
    case fileReadFailed(path: String)

    var errorDescription: String? {
        switch self {
        case .gitNotFound:
            return "Could not find git at /usr/bin/git. Please install git (e.g. Xcode Command Line Tools on macOS)."
        case .cloneFailed(let repo, let exitCode):
            return "Failed to clone '\(repo)' (exit code \(exitCode)). Ensure the URL is correct and that you have access — for SSH repositories, verify that your SSH key is loaded and authorised for this host."
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
    /// Maps repository URL → local clone directory.
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

    func skillPaths(repository: String) async throws -> [String] {
        let cloneDir = try await clone(repository)
        return enumerateSkillPaths(in: cloneDir)
    }

    func downloadSkill(repository: String, path: String) async throws -> Data {
        let cloneDir = try await clone(repository)
        let fileURL = cloneDir.resolvingSymlinksInPath().appendingPathComponent(path)
        do {
            return try Data(contentsOf: fileURL)
        } catch {
            throw GitRepositorySkillFetcherError.fileReadFailed(path: path)
        }
    }

    // MARK: - Private

    private func clone(_ repository: String) async throws -> URL {
        if let cached = cloneCache[repository] {
            return cached
        }

        guard FileManager.default.fileExists(atPath: Self.gitExecutableURL.path) else {
            throw GitRepositorySkillFetcherError.gitNotFound
        }

        let tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
        let gitURL = cloneURL(for: repository)

        let exitCode = try await subprocessRunner.run(
            executableURL: Self.gitExecutableURL,
            arguments: ["clone", "--quiet", "--depth", "1", gitURL, tempDir.path]
        )

        guard exitCode == 0 else {
            throw GitRepositorySkillFetcherError.cloneFailed(repository: repository, exitCode: exitCode)
        }

        cloneCache[repository] = tempDir
        return tempDir
    }

    /// Returns a git-clonable URL for the given repository reference.
    ///
    /// SSH and HTTPS/HTTP URLs are passed through unchanged; `owner/repo` shorthand is
    /// expanded to `https://github.com/owner/repo`.
    private func cloneURL(for repository: String) -> String {
        if repository.hasPrefix("git@")
            || repository.hasPrefix("https://")
            || repository.hasPrefix("http://") {
            return repository
        }
        return "https://github.com/\(repository)"
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
            includingPropertiesForKeys: [.isDirectoryKey],
            options: [.skipsHiddenFiles]
        ) else {
            return []
        }

        let baseComponents = resolvedBase.pathComponents
        var allPaths: [String] = []

        while let fileURL = enumerator.nextObject() as? URL {
            let isDir = (try? fileURL.resourceValues(forKeys: [.isDirectoryKey]).isDirectory) ?? false
            if isDir { continue }

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
