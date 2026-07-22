//  SkillLatestVersionResolverMock.swift

import Foundation
@testable import ManagerCore

final class SkillLatestVersionResolverMock: SkillLatestVersionResolving, @unchecked Sendable {

    /// SHA (or error) to return, keyed by repository.
    var resultsByRepository: [String: Result<String, Error>] = [:]
    /// Repositories the resolver was actually asked to resolve, in call order.
    var recordedRepositories: [String] = []

    func resolveLatestVersion(repository: String) async throws -> String {
        recordedRepositories.append(repository)
        guard let result = resultsByRepository[repository] else {
            fatalError("SkillLatestVersionResolverMock has no stubbed result for repository '\(repository)'")
        }
        return try result.get()
    }
}
