//  EnvFileLoaderTests.swift

import Foundation
import Testing
@testable import LucaFoundation
@testable import PipelineCore

struct EnvFileLoaderTests {

    private let sut = EnvFileLoader()

    private func makeTempURL() -> URL {
        FileManager.default.temporaryDirectory.appending(component: UUID().uuidString + ".env")
    }

    // MARK: - Valid dotenv

    @Test
    func test_load_validKeyValuePairs() throws {
        let url = makeTempURL()
        let content = "API_KEY=secret123\nENVIRONMENT=staging\n"
        try content.write(to: url, atomically: true, encoding: .utf8)
        defer { try? FileManager.default.removeItem(at: url) }

        let result = try sut.load(from: url)

        #expect(result["API_KEY"] == "secret123")
        #expect(result["ENVIRONMENT"] == "staging")
        #expect(result.count == 2)
    }

    @Test
    func test_load_quotedValues_stripsQuotes() throws {
        let url = makeTempURL()
        let content = "DOUBLE=\"hello world\"\nSINGLE='foo bar'\n"
        try content.write(to: url, atomically: true, encoding: .utf8)
        defer { try? FileManager.default.removeItem(at: url) }

        let result = try sut.load(from: url)

        #expect(result["DOUBLE"] == "hello world")
        #expect(result["SINGLE"] == "foo bar")
    }

    @Test
    func test_load_commentLines_areSkipped() throws {
        let url = makeTempURL()
        let content = "# this is a comment\nKEY=value\n# another comment\n"
        try content.write(to: url, atomically: true, encoding: .utf8)
        defer { try? FileManager.default.removeItem(at: url) }

        let result = try sut.load(from: url)

        #expect(result.count == 1)
        #expect(result["KEY"] == "value")
    }

    @Test
    func test_load_emptyLines_areSkipped() throws {
        let url = makeTempURL()
        let content = "\nKEY=value\n\n"
        try content.write(to: url, atomically: true, encoding: .utf8)
        defer { try? FileManager.default.removeItem(at: url) }

        let result = try sut.load(from: url)

        #expect(result.count == 1)
        #expect(result["KEY"] == "value")
    }

    @Test
    func test_load_emptyFile() throws {
        let url = makeTempURL()
        try "".write(to: url, atomically: true, encoding: .utf8)
        defer { try? FileManager.default.removeItem(at: url) }

        let result = try sut.load(from: url)

        #expect(result.isEmpty)
    }

    @Test
    func test_load_valueWithEquals_preservesRemainder() throws {
        let url = makeTempURL()
        let content = "URL=https://example.com?a=1&b=2\n"
        try content.write(to: url, atomically: true, encoding: .utf8)
        defer { try? FileManager.default.removeItem(at: url) }

        let result = try sut.load(from: url)

        #expect(result["URL"] == "https://example.com?a=1&b=2")
    }

    // MARK: - Missing file

    @Test
    func test_load_missingFile_throwsFileNotFound() {
        let url = URL(fileURLWithPath: "/nonexistent/path/.env")

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
    func test_load_lineWithoutEquals_throwsInvalidFormat() throws {
        let url = makeTempURL()
        let content = "INVALID_LINE\n"
        try content.write(to: url, atomically: true, encoding: .utf8)
        defer { try? FileManager.default.removeItem(at: url) }

        #expect(throws: EnvFileLoader.EnvFileLoaderError.invalidFormat) {
            try sut.load(from: url)
        }
    }

    // MARK: - Error descriptions

    @Test
    func test_errorDescription_fileNotFound_containsPath() {
        let url = URL(fileURLWithPath: "/some/path/.env")
        let error = EnvFileLoader.EnvFileLoaderError.fileNotFound(url)
        #expect(error.errorDescription?.contains("/some/path/.env") == true)
    }

    @Test
    func test_errorDescription_invalidFormat_isReadable() {
        let error = EnvFileLoader.EnvFileLoaderError.invalidFormat
        #expect(error.errorDescription != nil)
        #expect(error.errorDescription?.isEmpty == false)
    }
}
