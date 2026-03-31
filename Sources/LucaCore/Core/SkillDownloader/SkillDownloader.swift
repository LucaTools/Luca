//  SkillDownloader.swift

import Foundation

/// Downloads skill files from a GitHub repository.
///
/// `SkillDownloader` parses the repository reference from a ``SkillSet``, fetches the list of
/// skill-related paths from the GitHub tree, optionally filters by requested skill names, downloads
/// every file in each skill's directory, and returns the results as `(name, files)` pairs where
/// `files` contains all ``SkillFile`` values with paths relative to the skill root.
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
    /// - Returns: An array of `(name, files)` tuples. Each `files` array contains every file in the
    ///   skill's directory with paths relative to the skill root (e.g. `"SKILL.md"`,
    ///   `"resources/template.md"`).
    func download(skillSet: SkillSet) async throws -> [(name: String, files: [SkillFile])] {
        let (owner, repo) = try parseRepository(skillSet.repository)

        let allPaths: [String]
        do {
            allPaths = try await gitHubClient.skillPaths(owner: owner, repo: repo)
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

        let skillMdPaths = allPaths.filter { $0.hasSuffix("SKILL.md") }
        guard !skillMdPaths.isEmpty else {
            throw SkillDownloaderError.noSkillsFound(repository: skillSet.repository)
        }

        // Phase 1: build skill entries — name, skill directory, and the set of file paths to download.
        // For a root SKILL.md the name comes from frontmatter, so we download it early and cache it.
        struct SkillEntry {
            let name: String
            let skillDir: String        // empty string for a root-level SKILL.md
            let filePaths: [String]
            let cachedRootContent: Data? // non-nil only for the root SKILL.md skill
        }

        var skillEntries: [SkillEntry] = []

        for skillMdPath in skillMdPaths {
            if skillMdPath == "SKILL.md" {
                // Root skill: fetch early to extract the skill name from frontmatter.
                let content: Data
                do {
                    content = try await gitHubClient.downloadSkill(owner: owner, repo: repo, path: skillMdPath)
                } catch {
                    throw SkillDownloaderError.downloadFailed(path: skillMdPath)
                }
                let name = (try? frontmatterParser.skillName(from: content)) ?? repo
                skillEntries.append(SkillEntry(
                    name: name,
                    skillDir: "",
                    filePaths: ["SKILL.md"],
                    cachedRootContent: content
                ))
            } else {
                let skillDir = URL(fileURLWithPath: skillMdPath).deletingLastPathComponent().path
                let name = URL(fileURLWithPath: skillDir).lastPathComponent
                // Include every path that lives inside this skill's directory.
                let filePaths = allPaths.filter { $0.hasPrefix(skillDir + "/") }
                skillEntries.append(SkillEntry(
                    name: name,
                    skillDir: skillDir,
                    filePaths: filePaths,
                    cachedRootContent: nil
                ))
            }
        }

        // Phase 2: filter by requested skill names.
        if !skillSet.skills.isEmpty {
            for requestedName in skillSet.skills {
                guard skillEntries.contains(where: { $0.name == requestedName }) else {
                    throw SkillDownloaderError.skillNotFound(name: requestedName, repository: skillSet.repository)
                }
            }
            skillEntries = skillEntries.filter { skillSet.skills.contains($0.name) }
        }

        // Phase 3: download all files for each skill and compute relative paths.
        var results: [(name: String, files: [SkillFile])] = []
        for entry in skillEntries {
            var files: [SkillFile] = []
            for filePath in entry.filePaths {
                let content: Data
                // Reuse the cached root SKILL.md content to avoid a redundant HTTP request.
                if entry.skillDir.isEmpty, let cached = entry.cachedRootContent {
                    content = cached
                } else {
                    do {
                        content = try await gitHubClient.downloadSkill(owner: owner, repo: repo, path: filePath)
                    } catch {
                        throw SkillDownloaderError.downloadFailed(path: filePath)
                    }
                }
                let relativePath = entry.skillDir.isEmpty
                    ? filePath
                    : String(filePath.dropFirst(entry.skillDir.count + 1))
                files.append(SkillFile(relativePath: relativePath, content: content))
            }
            results.append((name: entry.name, files: files))
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
