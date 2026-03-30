//  SkillDownloader.swift

import Foundation

/// Downloads skill files from a GitHub repository.
///
/// `SkillDownloader` parses the repository reference from a ``SkillSet``, fetches the list of
/// `SKILL.md` paths from the GitHub tree, optionally filters by requested skill names, downloads
/// each skill's content, and returns the results as `(name, content)` pairs.
struct SkillDownloader: SkillDownloading {

    // MARK: - Error

    /// Errors thrown by ``SkillDownloader``.
    enum SkillDownloaderError: Error, LocalizedError, Equatable {
        /// The repository string cannot be parsed as `owner/repo` or a GitHub HTTPS URL.
        case invalidRepository(String)
        /// GitHub returned 404 for the given repository.
        case repositoryNotFound(String)
        /// GitHub returned 403 or 429 (rate-limit exceeded).
        case rateLimitExceeded
        /// The repository tree contained no `SKILL.md` files.
        case noSkillsFound(repository: String)
        /// A requested skill name was not found in the repository.
        case skillNotFound(name: String, repository: String)
        /// Downloading the skill at the given path failed.
        case downloadFailed(path: String)

        var errorDescription: String? {
            switch self {
            case .invalidRepository(let repo):
                return "'\(repo)' could not be parsed as a GitHub repository reference (expected 'owner/repo' or a GitHub HTTPS URL)."
            case .repositoryNotFound(let repo):
                return "Repository '\(repo)' was not found on GitHub."
            case .rateLimitExceeded:
                return "GitHub API rate limit exceeded. Please wait before trying again."
            case .noSkillsFound(let repo):
                return "No SKILL.md files were found in '\(repo)'."
            case .skillNotFound(let name, let repo):
                return "Skill '\(name)' was not found in repository '\(repo)'."
            case .downloadFailed(let path):
                return "Failed to download skill at path '\(path)'."
            }
        }
    }

    // MARK: - Properties

    private let gitHubClient: GitHubSkillTreeFetching
    private let frontmatterParser: SkillFrontmatterParsing

    // MARK: - Init

    init(
        gitHubClient: GitHubSkillTreeFetching = GitHubSkillTreeClient(),
        frontmatterParser: SkillFrontmatterParsing = SkillFrontmatterParser()
    ) {
        self.gitHubClient = gitHubClient
        self.frontmatterParser = frontmatterParser
    }

    // MARK: - SkillDownloading

    /// Downloads skills from the repository described by `skillSet`.
    ///
    /// - Parameter skillSet: The ``SkillSet`` describing the repository and optional skill name filter.
    /// - Returns: An array of `(name, content)` tuples for each downloaded skill.
    func download(skillSet: SkillSet) async throws -> [(name: String, content: Data)] {
        let (owner, repo) = try parseRepository(skillSet.repository)

        let paths: [String]
        do {
            paths = try await gitHubClient.skillPaths(owner: owner, repo: repo)
        } catch let clientError as GitHubSkillTreeClientError {
            if case .unexpectedResponse(let statusCode) = clientError {
                switch statusCode {
                case 404:
                    throw SkillDownloaderError.repositoryNotFound(skillSet.repository)
                case 403, 429:
                    throw SkillDownloaderError.rateLimitExceeded
                default:
                    throw clientError
                }
            } else {
                throw clientError
            }
        }

        guard !paths.isEmpty else {
            throw SkillDownloaderError.noSkillsFound(repository: skillSet.repository)
        }

        // Separate root SKILL.md (name comes from frontmatter) from directory-based skills
        let rootPath = "SKILL.md"
        let nonRootPaths = paths.filter { $0 != rootPath }

        // Build name→path mapping for non-root skills (name derived from parent directory)
        var namePathPairs: [(name: String, path: String)] = nonRootPaths.map { path in
            let name = URL(fileURLWithPath: path).deletingLastPathComponent().lastPathComponent
            return (name: name, path: path)
        }

        // Handle root SKILL.md: download first to extract name from frontmatter
        var rootSkillData: (name: String, path: String, content: Data)? = nil
        if paths.contains(rootPath) {
            let content: Data
            do {
                content = try await gitHubClient.downloadSkill(owner: owner, repo: repo, path: rootPath)
            } catch {
                throw SkillDownloaderError.downloadFailed(path: rootPath)
            }
            let name = (try? frontmatterParser.skillName(from: content)) ?? repo
            rootSkillData = (name: name, path: rootPath, content: content)
            namePathPairs.append((name: name, path: rootPath))
        }

        // Filter by requested skill names if specified
        var filteredPairs = namePathPairs
        if !skillSet.skills.isEmpty {
            for requestedName in skillSet.skills {
                let found = namePathPairs.contains { $0.name == requestedName }
                if !found {
                    throw SkillDownloaderError.skillNotFound(name: requestedName, repository: skillSet.repository)
                }
            }
            filteredPairs = namePathPairs.filter { skillSet.skills.contains($0.name) }
        }

        // Download remaining skills (skip root which was already downloaded)
        var results: [(name: String, content: Data)] = []
        for pair in filteredPairs {
            if pair.path == rootPath, let root = rootSkillData {
                results.append((name: root.name, content: root.content))
            } else {
                let content: Data
                do {
                    content = try await gitHubClient.downloadSkill(owner: owner, repo: repo, path: pair.path)
                } catch {
                    throw SkillDownloaderError.downloadFailed(path: pair.path)
                }
                results.append((name: pair.name, content: content))
            }
        }

        return results
    }

    // MARK: - Private Helpers

    /// Parses a repository reference into `(owner, repo)`.
    ///
    /// Supports `owner/repo` shorthand and full HTTPS GitHub URLs (with optional `.git` suffix).
    private func parseRepository(_ repository: String) throws -> (owner: String, repo: String) {
        // Full HTTPS URL: https://github.com/owner/repo or https://github.com/owner/repo.git
        if repository.hasPrefix("https://github.com/") || repository.hasPrefix("http://github.com/") {
            let withoutScheme = repository
                .replacingOccurrences(of: "https://github.com/", with: "")
                .replacingOccurrences(of: "http://github.com/", with: "")
            let components = withoutScheme.split(separator: "/", maxSplits: 1).map(String.init)
            guard components.count == 2, !components[0].isEmpty, !components[1].isEmpty else {
                throw SkillDownloaderError.invalidRepository(repository)
            }
            var repoName = components[1]
            if repoName.hasSuffix(".git") { repoName = String(repoName.dropLast(4)) }
            return (owner: components[0], repo: repoName)
        }

        // Shorthand: owner/repo
        let components = repository.split(separator: "/", maxSplits: 1).map(String.init)
        guard components.count == 2, !components[0].isEmpty, !components[1].isEmpty else {
            throw SkillDownloaderError.invalidRepository(repository)
        }
        return (owner: components[0], repo: components[1])
    }
}
