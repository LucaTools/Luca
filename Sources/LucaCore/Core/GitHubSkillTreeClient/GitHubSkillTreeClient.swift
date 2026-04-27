//  GitHubSkillTreeClient.swift

import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

// MARK: - Error

/// Errors thrown by ``GitHubSkillTreeClient``.
enum GitHubSkillTreeClientError: Error, LocalizedError, Equatable {
    /// The repository reference could not be parsed or a URL could not be constructed.
    case invalidURL
    /// GitHub returned a non-200 HTTP status code.
    case unexpectedResponse(statusCode: Int)
    /// The JSON response body could not be decoded into the expected model.
    case decodingFailed
    /// The repository tree was truncated due to its size.
    case treeTruncated

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Could not construct the GitHub API URL."
        case .unexpectedResponse(let statusCode):
            return "Unexpected HTTP response from GitHub: \(statusCode)."
        case .decodingFailed:
            return "Failed to decode the GitHub API response."
        case .treeTruncated:
            return "The repository tree was truncated. The repository may be too large to fetch all skills."
        }
    }
}

// MARK: - Implementation

/// Retrieves skill metadata from a GitHub repository using the Git Trees API and raw content endpoint.
///
/// This client is suitable for public repositories and private repositories where a GitHub
/// personal access token is available. For private repositories or GitHub Enterprise instances
/// where SSH-key authentication is preferred, use ``GitRepositorySkillFetcher`` instead.
struct GitHubSkillTreeClient: SkillRepositoryFetching {

    // MARK: - Exclusion Lists

    /// File names that are never downloaded, regardless of location.
    private static let excludedFileNames: Set<String> = ["metadata.json"]

    /// Directory names whose contents are never downloaded.
    private static let excludedDirectories: Set<String> = [".git", "__pycache__", "__pypackages__"]

    // MARK: - Properties

    private var dataDownloader: DataDownloading

    // MARK: - Init

    init(dataDownloader: DataDownloading = DataDownloader()) {
        self.dataDownloader = dataDownloader
    }

    // MARK: - SkillRepositoryFetching

    func skillPaths(repository: String, ref: String?) async throws -> [String] {
        let (owner, repo, host) = try parseRepository(repository)
        let urlString = apiURL(host: host, owner: owner, repo: repo, ref: ref)
        guard let url = URL(string: urlString) else {
            throw GitHubSkillTreeClientError.invalidURL
        }

        var request = URLRequest(url: url)
        request.setValue("application/vnd.github.v3+json", forHTTPHeaderField: "Accept")
        request.setValue("luca.tools.cli", forHTTPHeaderField: "User-Agent")

        let (data, response) = try await dataDownloader.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw GitHubSkillTreeClientError.unexpectedResponse(statusCode: 0)
        }

        guard httpResponse.statusCode == 200 else {
            throw GitHubSkillTreeClientError.unexpectedResponse(statusCode: httpResponse.statusCode)
        }

        do {
            let tree = try JSONDecoder().decode(GitHubTree.self, from: data)
            guard !tree.truncated else {
                throw GitHubSkillTreeClientError.treeTruncated
            }
            // "120000" is the Git mode for symbolic links
            let allBlobs = tree.tree.filter { $0.type == "blob" && $0.mode != "120000" }
            // Identify directories that contain a SKILL.md (excluding the repo root).
            // Use string splitting to preserve the relative path (not URL resolution).
            let skillDirectories: Set<String> = Set(
                allBlobs
                    .filter { $0.path.hasSuffix("SKILL.md") && $0.path != "SKILL.md" }
                    .map { $0.path.components(separatedBy: "/").dropLast().joined(separator: "/") }
            )
            // Include all SKILL.md files plus every file inside a skill directory,
            // except those matching the exclusion lists.
            return allBlobs
                .filter { item in
                    guard item.path.hasSuffix("SKILL.md") || skillDirectories.contains(where: { item.path.hasPrefix($0 + "/") }) else {
                        return false
                    }
                    let components = item.path.components(separatedBy: "/")
                    if let fileName = components.last, Self.excludedFileNames.contains(fileName) { return false }
                    if components.dropLast().contains(where: { Self.excludedDirectories.contains($0) }) { return false }
                    return true
                }
                .map(\.path)
        } catch let error as GitHubSkillTreeClientError {
            throw error
        } catch {
            throw GitHubSkillTreeClientError.decodingFailed
        }
    }

    func downloadSkill(repository: String, path: String, ref: String?) async throws -> Data {
        let (owner, repo, host) = try parseRepository(repository)
        let urlString = rawURL(host: host, owner: owner, repo: repo, path: path, ref: ref)
        guard let url = URL(string: urlString) else {
            throw GitHubSkillTreeClientError.invalidURL
        }

        var request = URLRequest(url: url)
        request.setValue("luca.tools.cli", forHTTPHeaderField: "User-Agent")

        let (data, response) = try await dataDownloader.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw GitHubSkillTreeClientError.unexpectedResponse(statusCode: 0)
        }

        guard httpResponse.statusCode == 200 else {
            throw GitHubSkillTreeClientError.unexpectedResponse(statusCode: httpResponse.statusCode)
        }

        return data
    }

    // MARK: - Private URL Helpers

    /// Returns the Git Trees API URL for the given host.
    ///
    /// Uses `api.github.com` for `github.com`; falls back to the GitHub Enterprise Server
    /// REST API base (`https://{host}/api/v3`) for any other hostname.
    private func apiURL(host: String, owner: String, repo: String, ref: String?) -> String {
        let base = host == "github.com"
            ? "https://api.github.com"
            : "https://\(host)/api/v3"
        let treeRef = ref ?? "HEAD"
        return "\(base)/repos/\(owner)/\(repo)/git/trees/\(treeRef)?recursive=1"
    }

    /// Returns the raw-content URL for the given host.
    ///
    /// Uses `raw.githubusercontent.com` for `github.com`; falls back to the GitHub Enterprise
    /// Server raw endpoint (`https://{host}/{owner}/{repo}/raw/{ref}/{path}`) for any other hostname.
    private func rawURL(host: String, owner: String, repo: String, path: String, ref: String?) -> String {
        let treeRef = ref ?? "HEAD"
        return host == "github.com"
            ? "https://raw.githubusercontent.com/\(owner)/\(repo)/\(treeRef)/\(path)"
            : "https://\(host)/\(owner)/\(repo)/raw/\(treeRef)/\(path)"
    }

    // MARK: - Private Repository Parsing

    /// Parses a repository reference into `(owner, repo, host)`.
    ///
    /// Supports SSH URLs, HTTPS URLs, and `owner/repo` shorthand.
    private func parseRepository(_ repository: String) throws -> (owner: String, repo: String, host: String) {
        // SSH URL: git@hostname:owner/repo or git@hostname:owner/repo.git
        if repository.hasPrefix("git@") {
            let withoutPrefix = String(repository.dropFirst(4))
            let colonParts = withoutPrefix.split(separator: ":", maxSplits: 1).map(String.init)
            guard colonParts.count == 2, !colonParts[0].isEmpty else {
                throw GitHubSkillTreeClientError.invalidURL
            }
            let host = colonParts[0]
            let pathParts = colonParts[1].split(separator: "/", maxSplits: 1).map(String.init)
            guard pathParts.count == 2, !pathParts[0].isEmpty, !pathParts[1].isEmpty else {
                throw GitHubSkillTreeClientError.invalidURL
            }
            var repoName = pathParts[1]
            if repoName.hasSuffix(".git") { repoName = String(repoName.dropLast(4)) }
            return (owner: pathParts[0], repo: repoName, host: host)
        }

        // Full HTTPS URL: https://hostname/owner/repo or https://hostname/owner/repo.git
        if let url = URL(string: repository), let scheme = url.scheme, (scheme == "https" || scheme == "http"), let host = url.host {
            let pathComponents = url.pathComponents.filter { $0 != "/" }
            guard pathComponents.count >= 2, !pathComponents[0].isEmpty, !pathComponents[1].isEmpty else {
                throw GitHubSkillTreeClientError.invalidURL
            }
            var repoName = pathComponents[1]
            if repoName.hasSuffix(".git") { repoName = String(repoName.dropLast(4)) }
            return (owner: pathComponents[0], repo: repoName, host: host)
        }

        // Shorthand: owner/repo (defaults to github.com)
        let components = repository.split(separator: "/", maxSplits: 1).map(String.init)
        guard components.count == 2, !components[0].isEmpty, !components[1].isEmpty else {
            throw GitHubSkillTreeClientError.invalidURL
        }
        return (owner: components[0], repo: components[1], host: "github.com")
    }
}

// MARK: - Private Decodable Models

private struct GitHubTree: Decodable {
    let tree: [GitHubTreeItem]
    let truncated: Bool
}

private struct GitHubTreeItem: Decodable {
    let path: String
    let type: String
    let mode: String?
}
