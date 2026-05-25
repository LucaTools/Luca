//  SkillDownloaderMock.swift

import Foundation
@testable import LucaFoundation
@testable import ManagerCore

final class SkillDownloaderMock: SkillDownloading, @unchecked Sendable {

    var downloadResult: Result<[(name: String, files: [SkillFile])], Error> = .success([])
    var downloadCalled = false
    var lastSkillSet: SkillSet?

    func download(skillSet: SkillSet) async throws -> [(name: String, files: [SkillFile])] {
        downloadCalled = true
        lastSkillSet = skillSet
        return try downloadResult.get()
    }
}
