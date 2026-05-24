//  ParameterResolvingMock.swift

import Foundation
@testable import LucaCore

final class ParameterResolvingMock: ParameterResolving {
    var stubbedResult: [String: String] = [:]
    var stubbedError: Error?

    func resolve(declared: [PipelineParameter], provided: [String: String]) throws -> [String: String] {
        if let error = stubbedError { throw error }
        return stubbedResult
    }
}
