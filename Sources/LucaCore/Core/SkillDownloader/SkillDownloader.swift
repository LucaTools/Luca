//  SkillDownloader.swift

import Foundation

/// Downloads skill files from a repository.
///
/// `SkillDownloader` parses the repository reference from a ``SkillSet``, fetches the list of
/// skill-related paths, optionally filters by requested skill names, downloads every file in
/// each skill's directory, and returns the results as `(name, files)` pairs where `files`
/// contains all ``SkillFile`` values with paths relative to the skill root.
struct SkillDownloader: SkillDownloading {

    // MARK: - Error

    /// Errors thrown by ``SkillDownloader``.
    enum SkillDownloaderError: Error, LocalizedError, Equatable {
        /// The repository string cannot be parsed as `owner/repo`, an HTTPS URL, or an SSH URL.
        case invalidRepository(String)
        /// The git executable was not found on the system.
        case gitNotFound
        /// Cloning the repository failed.
        case cloneFailed(repository: String)
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
                return "'\(repo)' could not be parsed as a repository reference (expected 'owner/repo', a GitHub HTTPS URL, or an SSH URL such as 'git@github.com:owner/repo.git')."
            case .gitNotFound:
                return "Could not find git at /usr/bin/git. Please install git (e.g. Xcode Command Line Tools on macOS)."
            case .cloneFailed(let repo):
                return "Failed to clone '\(repo)'. Ensure the URL is correct and that you have access — for SSH repositories, verify that your SSH key is loaded and authorised for this host."
            case .repositoryNotFound(let repo):
                return "Repository '\(repo)' was not found."
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

    private let skillFetcher: SkillRepositoryFetching
    private let frontmatterParser: SkillFrontmatterParsing

    // MARK: - Init

    init(
        skillFetcher: SkillRepositoryFetching = GitRepositorySkillFetcher(),
        frontmatterParser: SkillFrontmatterParsing = SkillFrontmatterParser()
    ) {
        self.skillFetcher = skillFetcher
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
        let repoName = try extractRepoName(from: skillSet.repository)

        let allPaths: [String]
        do {
            allPaths = try await skillFetcher.skillPaths(repository: skillSet.repository, ref: skillSet.version)
        } catch let fetcherError as GitRepositorySkillFetcherError {
            switch fetcherError {
            case .gitNotFound:
                throw SkillDownloaderError.gitNotFound
            case .cloneFailed(let repo, _):
                throw SkillDownloaderError.cloneFailed(repository: repo)
            case .checkoutFailed(let repo, _, _):
                throw SkillDownloaderError.cloneFailed(repository: repo)
            case .fileReadFailed(let path):
                throw SkillDownloaderError.downloadFailed(path: path)
            }
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
        // SKILL.md is always fetched early (for both root and nested skills) to extract the name from
        // frontmatter. The downloaded content is cached so Phase 3 can reuse it without a second request.
        struct SkillEntry {
            let name: String
            let skillDir: String        // empty string for a root-level SKILL.md
            let filePaths: [String]
            let cachedSkillMdContent: Data
        }

        var skillEntries: [SkillEntry] = []

        for skillMdPath in skillMdPaths {
            let content: Data
            do {
                content = try await skillFetcher.downloadSkill(repository: skillSet.repository, path: skillMdPath, ref: skillSet.version)
            } catch {
                throw SkillDownloaderError.downloadFailed(path: skillMdPath)
            }

            if skillMdPath == "SKILL.md" {
                // Root skill: name comes from frontmatter, falling back to the repo name.
                let name = (try? frontmatterParser.skillName(from: content)) ?? repoName
                skillEntries.append(SkillEntry(
                    name: name,
                    skillDir: "",
                    filePaths: ["SKILL.md"],
                    cachedSkillMdContent: content
                ))
            } else {
                // Nested skill: name comes from frontmatter, falling back to the parent folder name.
                // Use string splitting to preserve relative paths (not URL resolution).
                let skillDir = skillMdPath.components(separatedBy: "/").dropLast().joined(separator: "/")
                let folderName = skillDir.components(separatedBy: "/").last ?? skillDir
                let name = (try? frontmatterParser.skillName(from: content)) ?? folderName
                // Include every path that lives inside this skill's directory.
                let filePaths = allPaths.filter { $0.hasPrefix(skillDir + "/") }
                skillEntries.append(SkillEntry(
                    name: name,
                    skillDir: skillDir,
                    filePaths: filePaths,
                    cachedSkillMdContent: content
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
                // Reuse the cached SKILL.md content (fetched in Phase 1) to avoid a redundant request.
                let isSkillMd = entry.skillDir.isEmpty ? filePath == "SKILL.md" : filePath == entry.skillDir + "/SKILL.md"
                if isSkillMd {
                    content = entry.cachedSkillMdContent
                } else {
                    do {
                        content = try await skillFetcher.downloadSkill(repository: skillSet.repository, path: filePath, ref: skillSet.version)
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

    /// Extracts the repository name from a repository reference for use as a skill name fallback.
    ///
    /// Also validates that the reference is parseable, throwing ``SkillDownloaderError/invalidRepository(_:)``
    /// for strings that do not match any supported format.
    private func extractRepoName(from repository: String) throws -> String {
        // SSH: git@host:owner/repo.git → "repo"
        if repository.hasPrefix("git@") {
            let withoutPrefix = String(repository.dropFirst(4))
            guard let colonIndex = withoutPrefix.firstIndex(of: ":") else {
                throw SkillDownloaderError.invalidRepository(repository)
            }
            let path = String(withoutPrefix[withoutPrefix.index(after: colonIndex)...])
            let parts = path.split(separator: "/").map(String.init)
            guard parts.count == 2, !parts[0].isEmpty, !parts[1].isEmpty else {
                throw SkillDownloaderError.invalidRepository(repository)
            }
            var name = parts[1]
            if name.hasSuffix(".git") { name = String(name.dropLast(4)) }
            return name
        }

        // HTTPS/HTTP URL: https://host/owner/repo[.git] → "repo"
        if let url = URL(string: repository),
           let scheme = url.scheme, (scheme == "https" || scheme == "http"),
           url.host != nil {
            let pathComponents = url.pathComponents.filter { $0 != "/" }
            guard pathComponents.count >= 2, !pathComponents[1].isEmpty else {
                throw SkillDownloaderError.invalidRepository(repository)
            }
            var name = pathComponents[1]
            if name.hasSuffix(".git") { name = String(name.dropLast(4)) }
            return name
        }

        // Shorthand: owner/repo → "repo"
        let components = repository.split(separator: "/", maxSplits: 1).map(String.init)
        guard components.count == 2, !components[0].isEmpty, !components[1].isEmpty else {
            throw SkillDownloaderError.invalidRepository(repository)
        }
        return components[1]
    }
}
