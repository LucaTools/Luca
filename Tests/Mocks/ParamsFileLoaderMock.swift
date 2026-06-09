//  ParamsFileLoaderMock.swift

import Foundation
@testable import PipelineCore

class ParamsFileLoaderMock: ParamsFileLoading {

    var loadCallCount = 0
    var loadedURL: URL?
    var stubbedResult: Result<[String: String], Error> = .success([:])

    func load(from url: URL) throws -> [String: String] {
        loadCallCount += 1
        loadedURL = url
        switch stubbedResult {
        case .success(let params):
            return params
        case .failure(let error):
            throw error
        }
    }
}
