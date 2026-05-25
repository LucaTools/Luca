//  PipelineValidatorTests.swift

import Foundation
import Testing
@testable import LucaCore
@testable import PipelineCore

struct PipelineValidatorTests {

    // MARK: - First-word fallback

    @Test
    func test_validate_toolAvailable_succeeds() throws {
        let fileManager = ExecutableFileManagerMock(executablePaths: ["/usr/bin/swift"])
        let sut = PipelineValidator(fileManager: fileManager, pathEnvironment: "/usr/bin")
        let pipeline = makePipeline(tasks: [makeTask(command: "swift --version")])
        try sut.validate(pipeline)
    }

    @Test
    func test_validate_toolNotFound_throws() {
        let fileManager = ExecutableFileManagerMock(executablePaths: [])
        let sut = PipelineValidator(fileManager: fileManager, pathEnvironment: "/usr/bin")
        let pipeline = makePipeline(tasks: [makeTask(name: "Build", command: "missing-tool build")])
        #expect {
            try sut.validate(pipeline)
        } throws: { error in
            guard let validatorError = error as? PipelineValidator.PipelineValidatorError,
                  case .toolNotFound(let taskName, let tool) = validatorError else { return false }
            return taskName == "Build" && tool == "missing-tool"
        }
    }

    @Test
    func test_validate_stopsAtFirstMissingTool() {
        let fileManager = ExecutableFileManagerMock(executablePaths: ["/usr/bin/swift"])
        let sut = PipelineValidator(fileManager: fileManager, pathEnvironment: "/usr/bin")
        let pipeline = makePipeline(tasks: [
            makeTask(name: "Task A", command: "swift build"),
            makeTask(name: "Task B", command: "missing-tool run")
        ])
        #expect {
            try sut.validate(pipeline)
        } throws: { error in
            guard let validatorError = error as? PipelineValidator.PipelineValidatorError,
                  case .toolNotFound(let taskName, _) = validatorError else { return false }
            return taskName == "Task B"
        }
    }

    // MARK: - Explicit tools list

    @Test
    func test_validate_explicitToolsAvailable_succeeds() throws {
        let fileManager = ExecutableFileManagerMock(executablePaths: ["/usr/bin/tuist", "/usr/bin/swiftlint"])
        let sut = PipelineValidator(fileManager: fileManager, pathEnvironment: "/usr/bin")
        let task = makeTask(command: "tuist generate && swiftlint", tools: ["tuist", "swiftlint"])
        let pipeline = makePipeline(tasks: [task])
        try sut.validate(pipeline)
    }

    @Test
    func test_validate_explicitToolsOverrideFirstWord() {
        // Command first word is "echo" (available), explicit tools list has "missing-tool"
        let fileManager = ExecutableFileManagerMock(executablePaths: ["/usr/bin/echo"])
        let sut = PipelineValidator(fileManager: fileManager, pathEnvironment: "/usr/bin")
        let task = makeTask(command: "echo hello", tools: ["missing-tool"])
        let pipeline = makePipeline(tasks: [task])
        #expect {
            try sut.validate(pipeline)
        } throws: { error in
            guard let validatorError = error as? PipelineValidator.PipelineValidatorError,
                  case .toolNotFound(_, let tool) = validatorError else { return false }
            return tool == "missing-tool"
        }
    }

    // MARK: - Absolute path tools

    @Test
    func test_validate_absolutePathTool_checkedDirectly() throws {
        let fileManager = ExecutableFileManagerMock(executablePaths: ["/usr/local/bin/my-tool"])
        let sut = PipelineValidator(fileManager: fileManager, pathEnvironment: "")
        let task = makeTask(command: "/usr/local/bin/my-tool --flag")
        let pipeline = makePipeline(tasks: [task])
        try sut.validate(pipeline)
    }

    // MARK: - toolCheckResults

    @Test
    func test_toolCheckResults_returnsPerTaskResults() {
        let fileManager = ExecutableFileManagerMock(executablePaths: ["/usr/bin/swift"])
        let sut = PipelineValidator(fileManager: fileManager, pathEnvironment: "/usr/bin")
        let pipeline = makePipeline(tasks: [
            makeTask(name: "Task A", command: "swift build"),
            makeTask(name: "Task B", command: "missing-tool run")
        ])
        let results = sut.toolCheckResults(for: pipeline)
        #expect(results.count == 2)
        #expect(results[0].count == 1)
        #expect(results[0][0].tool == "swift")
        #expect(results[0][0].available == true)
        #expect(results[1].count == 1)
        #expect(results[1][0].tool == "missing-tool")
        #expect(results[1][0].available == false)
    }

    @Test
    func test_toolCheckResults_explicitToolsList_returnsOneResultPerTool() {
        let fileManager = ExecutableFileManagerMock(executablePaths: ["/usr/bin/tuist"])
        let sut = PipelineValidator(fileManager: fileManager, pathEnvironment: "/usr/bin")
        let task = makeTask(command: "some-cmd", tools: ["tuist", "missing-tool"])
        let results = sut.toolCheckResults(for: makePipeline(tasks: [task]))
        #expect(results.count == 1)
        #expect(results[0].count == 2)
        #expect(results[0][0].available == true)
        #expect(results[0][1].available == false)
    }

    // MARK: - Edge cases

    @Test
    func test_validate_emptyCommand_succeedsWithoutCheckingAnyTool() throws {
        let fileManager = ExecutableFileManagerMock(executablePaths: [])
        let sut = PipelineValidator(fileManager: fileManager, pathEnvironment: "/usr/bin")
        let pipeline = makePipeline(tasks: [makeTask(command: "")])
        // An empty command produces no tools to check; validation passes silently.
        try sut.validate(pipeline)
    }

    // MARK: - Error descriptions

    @Test
    func test_errorDescription_toolNotFound_containsTaskNameAndTool() {
        let error = PipelineValidator.PipelineValidatorError.toolNotFound(taskName: "Build", tool: "tuist")
        let description = error.errorDescription ?? ""
        #expect(description.contains("Build"))
        #expect(description.contains("tuist"))
    }

    // MARK: - Helpers

    private func makePipeline(tasks: [PipelineTask]) -> Pipeline {
        Pipeline(tasks: tasks, env: nil, workingDirectory: nil)
    }

    private func makeTask(name: String = "Task", command: String, tools: [String]? = nil) -> PipelineTask {
        PipelineTask(name: name, command: command, tools: tools, env: nil, continueOnError: nil, workingDirectory: nil)
    }
}

// MARK: - Mock

private class ExecutableFileManagerMock: PipelineValidatorFileManaging {
    private let executablePaths: Set<String>

    init(executablePaths: [String]) {
        self.executablePaths = Set(executablePaths)
    }

    func isExecutableFile(atPath path: String) -> Bool {
        executablePaths.contains(path)
    }
}
