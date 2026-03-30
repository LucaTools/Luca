//  GitHubSkillTreeClientMock.swift

import Foundation
@testable import LucaCore

final class GitHubSkillTreeClientMock: GitHubSkillTreeClientProtocol {

    var skillPathsResult: Result<[String], Error> = .success([])
    var downloadSkillResult: Result<Data, Error> = .success(Data())
    var skillPathsCalled = false
    var downloadSkillCalled = false

    func skillPaths(owner: String, repo: String) async throws -> [String] {
        skillPathsCalled = true
        return try skillPathsResult.get()
    }

    func downloadSkill(owner: String, repo: String, path: String) async throws -> Data {
        downloadSkillCalled = true
        return try downloadSkillResult.get()
    }
}
