//  GitHubSkillTreeClientMock.swift

import Foundation
@testable import LucaCore
@testable import ManagerCore

final class GitHubSkillTreeClientMock: SkillRepositoryFetching, @unchecked Sendable {

    var skillPathsResult: Result<[String], Error> = .success([])
    var downloadSkillResult: Result<Data, Error> = .success(Data())
    var skillPathsCalled = false
    var downloadSkillCalled = false
    var capturedRef: String?

    func skillPaths(repository: String, ref: String?) async throws -> [String] {
        skillPathsCalled = true
        capturedRef = ref
        return try skillPathsResult.get()
    }

    func downloadSkill(repository: String, path: String, ref: String?) async throws -> Data {
        downloadSkillCalled = true
        capturedRef = ref
        return try downloadSkillResult.get()
    }
}
