//  EnvFileLoaderMock.swift

import Foundation
@testable import PipelineCore

final class EnvFileLoaderMock: EnvFileLoading, @unchecked Sendable {

    /// The URL last passed to ``load(from:)``.
    var recordedURL: URL?

    /// When set, ``load(from:)`` throws this error instead of returning ``stubbedResult``.
    var stubbedError: Error?

    /// The dictionary returned by ``load(from:)`` when ``stubbedError`` is `nil`.
    var stubbedResult: [String: String] = [:]

    func load(from url: URL) throws -> [String: String] {
        recordedURL = url
        if let error = stubbedError {
            throw error
        }
        return stubbedResult
    }
}
