//  SpecLoaderTests.swift

import Foundation
import Testing
@testable import LucaCore

struct SpecLoaderTests {

    @Test
    func test_loadSpec_validYAML_returnsSpec() throws {
        let sut = SpecLoader(fileManager: .default)

        let bundle = Bundle.module
        let path = try #require(bundle.url(forResource: "Lucafile_valid", withExtension: "yml"))

        let spec = try sut.loadSpec(at: path)
        let tools = try #require(spec.tools)

        #expect(tools.count == 4)
        #expect(tools[0].name == "FirebaseCLI")
        #expect(tools[1].name == "PackageGenerator")
        #expect(tools[2].name == "Sourcery")
        #expect(tools[3].name == "ToggleGen")
    }

    @Test
    func test_loadSpec_missingFile_throwsMissingSpec() throws {
        let sut = SpecLoader(fileManager: .default)

        let path = URL(fileURLWithPath: "/nonexistent/path/to/Lucafile")

        #expect {
            try sut.loadSpec(at: path)
        } throws: { error in
            guard let specError = error as? SpecLoader.SpecLoaderError,
                  case SpecLoader.SpecLoaderError.missingSpec = specError else { return false }
            return true
        }
    }

    @Test
    func test_loadSpec_invalidYAML_throwsInvalidSpec() throws {
        let sut = SpecLoader(fileManager: .default)

        let bundle = Bundle.module
        let path = try #require(bundle.url(forResource: "Lucafile_invalid", withExtension: "yml"))

        #expect {
            try sut.loadSpec(at: path)
        } throws: { error in
            guard let specError = error as? SpecLoader.SpecLoaderError,
                  case SpecLoader.SpecLoaderError.invalidSpec = specError else { return false }
            return true
        }
    }

    @Test
    func test_loadSpec_invalidYAML_errorDescriptionIsReadable() throws {
        let sut = SpecLoader(fileManager: .default)

        let bundle = Bundle.module
        let path = try #require(bundle.url(forResource: "Lucafile_invalid", withExtension: "yml"))

        #expect {
            try sut.loadSpec(at: path)
        } throws: { error in
            guard let specError = error as? SpecLoader.SpecLoaderError,
                  case SpecLoader.SpecLoaderError.invalidSpec = specError,
                  let description = specError.errorDescription else { return false }
            return !description.contains("NSUnderlyingError") && !description.contains("Error Domain=")
        }
    }
}
