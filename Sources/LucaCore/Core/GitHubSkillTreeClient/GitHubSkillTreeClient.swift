//  GitHubSkillTreeClient.swift

import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

// MARK: - Protocol

/// Fetches the list of skill paths from a GitHub repository's file tree, and downloads individual skill files.
protocol GitHubSkillTreeClientProtocol {
    /// Returns the paths of all `SKILL.md` blob items in the repository tree.
    ///
    /// - Parameters:
    ///   - owner: The GitHub repository owner (user or organisation).
    ///   - repo: The repository name.
    /// - Returns: An array of file paths whose last component is `SKILL.md`.
    func skillPaths(owner: String, repo: String) async throws -> [String]

    /// Downloads the raw content of a skill file.
    ///
    /// - Parameters:
    ///   - owner: The GitHub repository owner.
    ///   - repo: The repository name.
    ///   - path: The repository-relative path to the skill file.
    /// - Returns: The raw file data.
    func downloadSkill(owner: String, repo: String, path: String) async throws -> Data
}

// MARK: - Implementation

/// Retrieves skill metadata from a GitHub repository using the Git Trees API and raw content endpoint.
struct GitHubSkillTreeClient: GitHubSkillTreeClientProtocol {

    // MARK: - Error

    /// Errors thrown by ``GitHubSkillTreeClient``.
    enum GitHubSkillTreeClientError: Error, LocalizedError, Equatable {
        /// The URL could not be constructed from the provided parameters.
        case invalidURL
        /// GitHub returned a non-200 HTTP status code.
        case unexpectedResponse(statusCode: Int)
        /// The JSON response body could not be decoded into the expected model.
        case decodingFailed

        var errorDescription: String? {
            switch self {
            case .invalidURL:
                return "Could not construct the GitHub API URL."
            case .unexpectedResponse(let statusCode):
                return "Unexpected HTTP response from GitHub: \(statusCode)."
            case .decodingFailed:
                return "Failed to decode the GitHub API response."
            }
        }
    }

    // MARK: - Properties

    private var dataDownloader: DataDownloading

    // MARK: - Init

    init(dataDownloader: DataDownloading = DataDownloader()) {
        self.dataDownloader = dataDownloader
    }

    // MARK: - GitHubSkillTreeClientProtocol

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
            return tree.tree
                .filter { $0.type == "blob" && $0.path.hasSuffix("SKILL.md") }
                .map(\.path)
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

    enum CodingKeys: String, CodingKey {
        case path
        case type
    }
}
