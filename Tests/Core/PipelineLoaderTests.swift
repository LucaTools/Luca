//  PipelineLoaderTests.swift

import Foundation
import Testing
@testable import LucaCore

struct PipelineLoaderTests {

    private let sut = PipelineLoader(fileManager: .default)

    // MARK: - Valid pipeline

    @Test
    func test_loadPipeline_simplePipeline_returnsTasks() throws {
        let path = try #require(Bundle.module.url(forResource: "Pipeline_simple", withExtension: "yml"))
        let pipeline = try sut.loadPipeline(at: path)
        #expect(pipeline.tasks.count == 2)
        #expect(pipeline.tasks[0].name == "Print version")
        #expect(pipeline.tasks[0].command == "swift --version")
        #expect(pipeline.tasks[1].name == "Echo message")
    }

    @Test
    func test_loadPipeline_fullPipeline_decodesAllFields() throws {
        let path = try #require(Bundle.module.url(forResource: "Pipeline_full", withExtension: "yml"))
        let pipeline = try sut.loadPipeline(at: path)

        #expect(pipeline.env?["PIPELINE_VAR"] == "pipeline-value")
        #expect(pipeline.workingDirectory == "ios/")
        #expect(pipeline.tasks.count == 5)

        let taskWithEnv = pipeline.tasks[1]
        #expect(taskWithEnv.env?["MY_VAR"] == "task-value")

        let taskWithTools = pipeline.tasks[2]
        #expect(taskWithTools.tools == ["swift"])

        let taskWithWorkDir = pipeline.tasks[3]
        #expect(taskWithWorkDir.workingDirectory == "backend/")

        let optionalTask = pipeline.tasks[4]
        #expect(optionalTask.continueOnError == true)
    }

    // MARK: - Missing file

    @Test
    func test_loadPipeline_missingFile_throwsMissingPipeline() {
        let path = URL(fileURLWithPath: "/nonexistent/path/to/pipeline.yml")
        #expect {
            try sut.loadPipeline(at: path)
        } throws: { error in
            guard let loaderError = error as? PipelineLoader.PipelineLoaderError,
                  case PipelineLoader.PipelineLoaderError.missingPipeline = loaderError else { return false }
            return true
        }
    }

    // MARK: - Invalid YAML

    @Test
    func test_loadPipeline_invalidYAML_throwsInvalidPipeline() throws {
        let path = try #require(Bundle.module.url(forResource: "Pipeline_invalid", withExtension: "yml"))
        #expect {
            try sut.loadPipeline(at: path)
        } throws: { error in
            guard let loaderError = error as? PipelineLoader.PipelineLoaderError,
                  case PipelineLoader.PipelineLoaderError.invalidPipeline = loaderError else { return false }
            return true
        }
    }

    @Test
    func test_loadPipeline_invalidYAML_errorDescriptionIsReadable() throws {
        let path = try #require(Bundle.module.url(forResource: "Pipeline_invalid", withExtension: "yml"))
        #expect {
            try sut.loadPipeline(at: path)
        } throws: { error in
            guard let loaderError = error as? PipelineLoader.PipelineLoaderError,
                  case PipelineLoader.PipelineLoaderError.invalidPipeline = loaderError,
                  let description = loaderError.errorDescription else { return false }
            return !description.contains("NSUnderlyingError") && !description.contains("Error Domain=")
        }
    }

    @Test
    func test_loadPipeline_syntaxErrorYAML_throwsInvalidPipeline() throws {
        let path = try #require(Bundle.module.url(forResource: "Pipeline_syntaxError", withExtension: "yml"))
        #expect {
            try sut.loadPipeline(at: path)
        } throws: { error in
            guard let loaderError = error as? PipelineLoader.PipelineLoaderError,
                  case PipelineLoader.PipelineLoaderError.invalidPipeline = loaderError else { return false }
            return true
        }
    }

    @Test
    func test_loadPipeline_missingRequiredKey_throwsInvalidPipeline() throws {
        let path = try #require(Bundle.module.url(forResource: "Pipeline_missingCommand", withExtension: "yml"))
        #expect {
            try sut.loadPipeline(at: path)
        } throws: { error in
            guard let loaderError = error as? PipelineLoader.PipelineLoaderError,
                  case PipelineLoader.PipelineLoaderError.invalidPipeline = loaderError else { return false }
            return true
        }
    }

    @Test
    func test_loadPipeline_nullTaskElement_throwsInvalidPipeline() throws {
        let path = try #require(Bundle.module.url(forResource: "Pipeline_nullCommand", withExtension: "yml"))
        #expect {
            try sut.loadPipeline(at: path)
        } throws: { error in
            guard let loaderError = error as? PipelineLoader.PipelineLoaderError,
                  case PipelineLoader.PipelineLoaderError.invalidPipeline = loaderError else { return false }
            return true
        }
    }

    @Test
    func test_loadPipeline_invalidUTF8Data_throwsInvalidPipeline() throws {
        let path = try #require(Bundle.module.url(forResource: "Pipeline_invalidUTF8", withExtension: "yml"))
        #expect {
            try sut.loadPipeline(at: path)
        } throws: { error in
            guard let loaderError = error as? PipelineLoader.PipelineLoaderError,
                  case PipelineLoader.PipelineLoaderError.invalidPipeline = loaderError else { return false }
            return true
        }
    }

    // MARK: - Error descriptions

    @Test
    func test_errorDescription_missingPipeline_containsPath() {
        let error = PipelineLoader.PipelineLoaderError.missingPipeline("/some/path.yml")
        #expect(error.errorDescription?.contains("/some/path.yml") == true)
    }
}
