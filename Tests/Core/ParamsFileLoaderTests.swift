//  ParamsFileLoaderTests.swift

import Foundation
import Testing
@testable import LucaFoundation
@testable import PipelineCore

struct ParamsFileLoaderTests {

    private let sut = ParamsFileLoader()

    private func makeTempURL() -> URL {
        FileManager.default.temporaryDirectory.appending(component: UUID().uuidString + ".params.yml")
    }

    // MARK: - Valid params file

    @Test
    func test_load_validFile_returnsParams() throws {
        let url = makeTempURL()
        let content = """
        params:
          - key: environment
            value: staging
          - key: upload
            value: "true"
        """
        try content.write(to: url, atomically: true, encoding: .utf8)
        defer { try? FileManager.default.removeItem(at: url) }

        let result = try sut.load(from: url)

        #expect(result["environment"] == "staging")
        #expect(result["upload"] == "true")
        #expect(result.count == 2)
    }

    @Test
    func test_load_emptyParams_returnsEmptyDict() throws {
        let url = makeTempURL()
        let content = "params: []\n"
        try content.write(to: url, atomically: true, encoding: .utf8)
        defer { try? FileManager.default.removeItem(at: url) }

        let result = try sut.load(from: url)

        #expect(result.isEmpty)
    }

    @Test
    func test_load_singleEntry_returnsOneParam() throws {
        let url = makeTempURL()
        let content = """
        params:
          - key: flavor
            value: release
        """
        try content.write(to: url, atomically: true, encoding: .utf8)
        defer { try? FileManager.default.removeItem(at: url) }

        let result = try sut.load(from: url)

        #expect(result["flavor"] == "release")
        #expect(result.count == 1)
    }

    @Test
    func test_load_valueWithSpecialChars_preserved() throws {
        let url = makeTempURL()
        let content = """
        params:
          - key: url
            value: https://example.com/path?a=1
        """
        try content.write(to: url, atomically: true, encoding: .utf8)
        defer { try? FileManager.default.removeItem(at: url) }

        let result = try sut.load(from: url)

        #expect(result["url"] == "https://example.com/path?a=1")
    }

    // MARK: - Missing file

    @Test
    func test_load_missingFile_throwsFileNotFound() {
        let url = URL(fileURLWithPath: "/nonexistent/path/ci.params.yml")

        #expect {
            try sut.load(from: url)
        } throws: { error in
            guard let loaderError = error as? ParamsFileLoader.ParamsFileLoaderError,
                  case ParamsFileLoader.ParamsFileLoaderError.fileNotFound = loaderError else { return false }
            return true
        }
    }

    // MARK: - Invalid format

    @Test
    func test_load_invalidYAML_throwsInvalidFormat() throws {
        let url = makeTempURL()
        let content = "this: is: not: valid: yaml: ["
        try content.write(to: url, atomically: true, encoding: .utf8)
        defer { try? FileManager.default.removeItem(at: url) }

        #expect(throws: ParamsFileLoader.ParamsFileLoaderError.invalidFormat) {
            try sut.load(from: url)
        }
    }

    @Test
    func test_load_missingParamsKey_throwsInvalidFormat() throws {
        let url = makeTempURL()
        let content = "tasks:\n  - name: build\n"
        try content.write(to: url, atomically: true, encoding: .utf8)
        defer { try? FileManager.default.removeItem(at: url) }

        #expect(throws: ParamsFileLoader.ParamsFileLoaderError.invalidFormat) {
            try sut.load(from: url)
        }
    }

    // MARK: - Error descriptions

    @Test
    func test_errorDescription_fileNotFound_containsPath() {
        let url = URL(fileURLWithPath: "/some/path/ci.params.yml")
        let error = ParamsFileLoader.ParamsFileLoaderError.fileNotFound(url)
        #expect(error.errorDescription?.contains("/some/path/ci.params.yml") == true)
    }

    @Test
    func test_errorDescription_invalidFormat_isReadable() {
        let error = ParamsFileLoader.ParamsFileLoaderError.invalidFormat
        #expect(error.errorDescription != nil)
        #expect(error.errorDescription?.isEmpty == false)
    }
}
