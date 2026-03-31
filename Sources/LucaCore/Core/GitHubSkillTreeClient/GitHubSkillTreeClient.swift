//  GitHubSkillTreeClient.swift

import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

// MARK: - Error

/// Errors thrown by ``GitHubSkillTreeClient``.
enum GitHubSkillTreeClientError: Error, LocalizedError, Equatable {
    /// The URL could not be constructed from the provided parameters.
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
struct GitHubSkillTreeClient: GitHubSkillTreeFetching {

    // MARK: - Properties

    private var dataDownloader: DataDownloading

    // MARK: - Init

    init(dataDownloader: DataDownloading = DataDownloader()) {
        self.dataDownloader = dataDownloader
    }

    // MARK: - GitHubSkillTreeFetching

    func skillPaths(owner: String, repo: String) async throws -> [String] {
        let urlString = "https://api.github.com/repos/\(owner)/\(repo)/git/trees/HEAD?recursive=1"
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
            let allBlobs = tree.tree.filter { $0.type == "blob" }
            // Identify directories that contain a SKILL.md (excluding the repo root).
            // Use string splitting to preserve the relative path (not URL resolution).
            let skillDirectories: Set<String> = Set(
                allBlobs
                    .filter { $0.path.hasSuffix("SKILL.md") && $0.path != "SKILL.md" }
                    .map { $0.path.components(separatedBy: "/").dropLast().joined(separator: "/") }
            )
            // Include all SKILL.md files plus every file inside a skill directory.
            return allBlobs
                .filter { item in
                    if item.path.hasSuffix("SKILL.md") { return true }
                    return skillDirectories.contains(where: { item.path.hasPrefix($0 + "/") })
                }
                .map(\.path)
        } catch let error as GitHubSkillTreeClientError {
            throw error
        } catch {
            throw GitHubSkillTreeClientError.decodingFailed
        }
    }

    func downloadSkill(owner: String, repo: String, path: String) async throws -> Data {
        let urlString = "https://raw.githubusercontent.com/\(owner)/\(repo)/HEAD/\(path)"
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
}

// MARK: - Private Decodable Models

private struct GitHubTree: Decodable {
    let tree: [GitHubTreeItem]
    let truncated: Bool
}

private struct GitHubTreeItem: Decodable {
    let path: String
    let type: String
}
