//  SkillDownloaderMock.swift

import Foundation
@testable import LucaCore

final class SkillDownloaderMock: SkillDownloading, @unchecked Sendable {

    var downloadResult: Result<[(name: String, content: Data)], Error> = .success([])
    var downloadCalled = false
    var lastSkillSet: SkillSet?

    func download(skillSet: SkillSet) async throws -> [(name: String, content: Data)] {
        downloadCalled = true
        lastSkillSet = skillSet
        return try downloadResult.get()
    }
}
