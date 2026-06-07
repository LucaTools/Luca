//  EnvFileLoaderTests.swift

import Foundation
import Testing
@testable import LucaFoundation
@testable import PipelineCore

struct EnvFileLoaderTests {

    private let sut = EnvFileLoader()

    private func makeTempURL() -> URL {
        FileManager.default.temporaryDirectory.appending(component: UUID().uuidString + ".yml")
    }

    // MARK: - Valid YAML

    @Test
    func test_load_validFlatYAML() throws {
        let url = makeTempURL()
        let content = "API_KEY: secret123\nENVIRONMENT: staging\n"
        try content.write(to: url, atomically: true, encoding: .utf8)
        defer { try? FileManager.default.removeItem(at: url) }

        let result = try sut.load(from: url)

        #expect(result["API_KEY"] == "secret123")
        #expect(result["ENVIRONMENT"] == "staging")
        #expect(result.count == 2)
    }

    @Test
    func test_load_emptyFile() throws {
        let url = makeTempURL()
        try "".write(to: url, atomically: true, encoding: .utf8)
        defer { try? FileManager.default.removeItem(at: url) }

        let result = try sut.load(from: url)

        #expect(result.isEmpty)
    }

    // MARK: - Missing file

    @Test
    func test_load_missingFile_throwsFileNotFound() {
        let url = URL(fileURLWithPath: "/nonexistent/path/env-vars.yml")

        #expect {
            try sut.load(from: url)
        } throws: { error in
            guard let loaderError = error as? EnvFileLoader.EnvFileLoaderError,
                  case EnvFileLoader.EnvFileLoaderError.fileNotFound = loaderError else { return false }
            return true
        }
    }

    // MARK: - Invalid format

    @Test
    func test_load_nestedYAML_throwsInvalidFormat() throws {
        let url = makeTempURL()
        let content = "outer:\n  inner: value\n"
        try content.write(to: url, atomically: true, encoding: .utf8)
        defer { try? FileManager.default.removeItem(at: url) }

        #expect {
            try sut.load(from: url)
        } throws: { error in
            guard let loaderError = error as? EnvFileLoader.EnvFileLoaderError,
                  case EnvFileLoader.EnvFileLoaderError.invalidFormat = loaderError else { return false }
            return true
        }
    }

    @Test
    func test_load_nonStringValue_throwsInvalidFormat() throws {
        let url = makeTempURL()
        let content = "PORT: 8080\n"
        try content.write(to: url, atomically: true, encoding: .utf8)
        defer { try? FileManager.default.removeItem(at: url) }

        #expect {
            try sut.load(from: url)
        } throws: { error in
            guard let loaderError = error as? EnvFileLoader.EnvFileLoaderError,
                  case EnvFileLoader.EnvFileLoaderError.invalidFormat = loaderError else { return false }
            return true
        }
    }

    @Test
    func test_load_booleanValue_throwsInvalidFormat() throws {
        let url = makeTempURL()
        let content = "ENABLED: true\n"
        try content.write(to: url, atomically: true, encoding: .utf8)
        defer { try? FileManager.default.removeItem(at: url) }

        #expect {
            try sut.load(from: url)
        } throws: { error in
            guard let loaderError = error as? EnvFileLoader.EnvFileLoaderError,
                  case EnvFileLoader.EnvFileLoaderError.invalidFormat = loaderError else { return false }
            return true
        }
    }

    // MARK: - Error descriptions

    @Test
    func test_errorDescription_fileNotFound_containsPath() {
        let url = URL(fileURLWithPath: "/some/path/env.yml")
        let error = EnvFileLoader.EnvFileLoaderError.fileNotFound(url)
        #expect(error.errorDescription?.contains("/some/path/env.yml") == true)
    }

    @Test
    func test_errorDescription_invalidFormat_isReadable() {
        let error = EnvFileLoader.EnvFileLoaderError.invalidFormat
        #expect(error.errorDescription != nil)
        #expect(error.errorDescription?.isEmpty == false)
    }
}
