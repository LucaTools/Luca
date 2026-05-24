//  ParameterResolverTests.swift

import Foundation
import Testing
@testable import LucaCore

struct ParameterResolverTests {

    private let sut = ParameterResolver()

    // MARK: - No parameters declared

    @Test
    func test_resolve_noDeclaredParams_noProvided_returnsEmpty() throws {
        let result = try sut.resolve(declared: [], provided: [:])
        #expect(result.isEmpty)
    }

    @Test
    func test_resolve_noDeclaredParams_withProvided_throwsUnknownParameter() {
        #expect(throws: ParameterResolver.ParameterResolverError.unknownParameter("flavor")) {
            try sut.resolve(declared: [], provided: ["flavor": "release"])
        }
    }

    // MARK: - Defaults

    @Test
    func test_resolve_paramWithDefault_notProvided_usesDefault() throws {
        let declared = [PipelineParameter(name: "flavor", defaultValue: "debug")]
        let result = try sut.resolve(declared: declared, provided: [:])
        #expect(result["flavor"] == "debug")
    }

    @Test
    func test_resolve_paramWithDefault_provided_usesProvidedValue() throws {
        let declared = [PipelineParameter(name: "flavor", defaultValue: "debug")]
        let result = try sut.resolve(declared: declared, provided: ["flavor": "release"])
        #expect(result["flavor"] == "release")
    }

    // MARK: - Required parameters

    @Test
    func test_resolve_requiredParam_notProvided_throwsMissingRequired() {
        let declared = [PipelineParameter(name: "upload")]
        #expect(throws: ParameterResolver.ParameterResolverError.missingRequiredParameter("upload")) {
            try sut.resolve(declared: declared, provided: [:])
        }
    }

    @Test
    func test_resolve_requiredParam_provided_returnsValue() throws {
        let declared = [PipelineParameter(name: "upload")]
        let result = try sut.resolve(declared: declared, provided: ["upload": "true"])
        #expect(result["upload"] == "true")
    }

    // MARK: - Unknown parameters

    @Test
    func test_resolve_unknownParamProvided_throwsUnknownParameter() {
        let declared = [PipelineParameter(name: "flavor", defaultValue: "debug")]
        #expect(throws: ParameterResolver.ParameterResolverError.unknownParameter("extra")) {
            try sut.resolve(declared: declared, provided: ["extra": "value"])
        }
    }

    // MARK: - Multiple parameters

    @Test
    func test_resolve_multipleParams_allProvided_returnsAllValues() throws {
        let declared = [
            PipelineParameter(name: "flavor", defaultValue: "debug"),
            PipelineParameter(name: "upload")
        ]
        let result = try sut.resolve(declared: declared, provided: ["flavor": "release", "upload": "true"])
        #expect(result["flavor"] == "release")
        #expect(result["upload"] == "true")
    }

    @Test
    func test_resolve_multipleParams_someMissingWithDefaults_usesMix() throws {
        let declared = [
            PipelineParameter(name: "flavor", defaultValue: "debug"),
            PipelineParameter(name: "upload", defaultValue: "false")
        ]
        let result = try sut.resolve(declared: declared, provided: ["flavor": "release"])
        #expect(result["flavor"] == "release")
        #expect(result["upload"] == "false")
    }

    // MARK: - Error descriptions

    @Test
    func test_errorDescription_unknownParameter_containsName() {
        let error = ParameterResolver.ParameterResolverError.unknownParameter("extra")
        #expect(error.errorDescription?.contains("extra") == true)
    }

    @Test
    func test_errorDescription_missingRequiredParameter_containsName() {
        let error = ParameterResolver.ParameterResolverError.missingRequiredParameter("upload")
        #expect(error.errorDescription?.contains("upload") == true)
    }
}
