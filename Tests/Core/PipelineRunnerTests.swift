//  PipelineRunnerTests.swift

import Foundation
import Testing
@testable import LucaCore

struct PipelineRunnerTests {

    private let invocationDir = URL(fileURLWithPath: "/project")

    // MARK: - Basic execution

    @Test
    func test_run_singleTask_executesOnce() async throws {
        let runner = SubprocessRunnerMock()
        let sut = PipelineRunner(subprocessRunner: runner, printer: PrinterMock())
        let pipeline = makePipeline(tasks: [makeTask(command: "echo hello")])
        try await sut.run(pipeline, currentDirectoryURL: invocationDir)
        #expect(runner.recordedArguments.count == 1)
        #expect(runner.recordedArguments[0] == ["-c", "set -eo pipefail && echo hello"])
    }

    @Test
    func test_run_multipleTasks_executesInOrder() async throws {
        let runner = SubprocessRunnerMock()
        let sut = PipelineRunner(subprocessRunner: runner, printer: PrinterMock())
        let pipeline = makePipeline(tasks: [
            makeTask(command: "echo first"),
            makeTask(command: "echo second")
        ])
        try await sut.run(pipeline, currentDirectoryURL: invocationDir)
        #expect(runner.recordedArguments.count == 2)
        #expect(runner.recordedArguments[0][1].hasSuffix("echo first"))
        #expect(runner.recordedArguments[1][1].hasSuffix("echo second"))
    }

    // MARK: - Stdin

    @Test
    func test_run_inheritStdinIsTrue() async throws {
        let runner = SubprocessRunnerMock()
        let sut = PipelineRunner(subprocessRunner: runner, printer: PrinterMock())
        let pipeline = makePipeline(tasks: [makeTask(command: "echo hello")])
        try await sut.run(pipeline, currentDirectoryURL: invocationDir)
        #expect(runner.recordedInheritStdin == [true])
    }

    // MARK: - Environment merging

    @Test
    func test_run_pipelineEnvPassedToTask() async throws {
        let runner = SubprocessRunnerMock()
        let sut = PipelineRunner(subprocessRunner: runner, printer: PrinterMock())
        let pipeline = makePipeline(tasks: [makeTask(command: "echo")], env: ["PIPELINE_KEY": "pipeline-val"])
        try await sut.run(pipeline, currentDirectoryURL: invocationDir)
        #expect(runner.recordedEnvironments[0]["PIPELINE_KEY"] == "pipeline-val")
    }

    @Test
    func test_run_taskEnvOverridesPipelineEnv() async throws {
        let runner = SubprocessRunnerMock()
        let sut = PipelineRunner(subprocessRunner: runner, printer: PrinterMock())
        let task = makeTask(command: "echo", env: ["KEY": "task-val"])
        let pipeline = makePipeline(tasks: [task], env: ["KEY": "pipeline-val"])
        try await sut.run(pipeline, currentDirectoryURL: invocationDir)
        #expect(runner.recordedEnvironments[0]["KEY"] == "task-val")
    }

    @Test
    func test_run_noEnv_passesEmptyEnvironment() async throws {
        let runner = SubprocessRunnerMock()
        let sut = PipelineRunner(subprocessRunner: runner, printer: PrinterMock())
        let pipeline = makePipeline(tasks: [makeTask(command: "echo")])
        try await sut.run(pipeline, currentDirectoryURL: invocationDir)
        #expect(runner.recordedEnvironments[0].isEmpty)
    }

    // MARK: - Working directory

    @Test
    func test_run_noWorkingDirectory_passesNil() async throws {
        let runner = SubprocessRunnerMock()
        let sut = PipelineRunner(subprocessRunner: runner, printer: PrinterMock())
        let pipeline = makePipeline(tasks: [makeTask(command: "echo")])
        try await sut.run(pipeline, currentDirectoryURL: invocationDir)
        #expect(runner.recordedWorkingDirectories[0] == nil)
    }

    @Test
    func test_run_relativeWorkingDirectory_resolvedAgainstInvocationDir() async throws {
        let runner = SubprocessRunnerMock()
        let sut = PipelineRunner(subprocessRunner: runner, printer: PrinterMock())
        let task = makeTask(command: "echo", workingDirectory: "ios/")
        let pipeline = makePipeline(tasks: [task])
        try await sut.run(pipeline, currentDirectoryURL: invocationDir)
        #expect(runner.recordedWorkingDirectories[0]?.path == "/project/ios")
    }

    @Test
    func test_run_absoluteWorkingDirectory_usedAsIs() async throws {
        let runner = SubprocessRunnerMock()
        let sut = PipelineRunner(subprocessRunner: runner, printer: PrinterMock())
        let task = makeTask(command: "echo", workingDirectory: "/absolute/path")
        let pipeline = makePipeline(tasks: [task])
        try await sut.run(pipeline, currentDirectoryURL: invocationDir)
        #expect(runner.recordedWorkingDirectories[0]?.path == "/absolute/path")
    }

    @Test
    func test_run_taskWorkingDirectoryOverridesPipelineDefault() async throws {
        let runner = SubprocessRunnerMock()
        let sut = PipelineRunner(subprocessRunner: runner, printer: PrinterMock())
        let task = makeTask(command: "echo", workingDirectory: "ios/")
        let pipeline = makePipeline(tasks: [task], workingDirectory: "backend/")
        try await sut.run(pipeline, currentDirectoryURL: invocationDir)
        #expect(runner.recordedWorkingDirectories[0]?.path == "/project/ios")
    }

    @Test
    func test_run_pipelineLevelWorkingDirectory_appliedWhenTaskHasNone() async throws {
        let runner = SubprocessRunnerMock()
        let sut = PipelineRunner(subprocessRunner: runner, printer: PrinterMock())
        let task = makeTask(command: "echo")
        let pipeline = makePipeline(tasks: [task], workingDirectory: "backend/")
        try await sut.run(pipeline, currentDirectoryURL: invocationDir)
        #expect(runner.recordedWorkingDirectories[0]?.path == "/project/backend")
    }

    // MARK: - Failure handling

    @Test
    func test_run_taskFails_throwsTaskFailed() async throws {
        let runner = SubprocessRunnerMock()
        runner.exitCodes = [1]
        let sut = PipelineRunner(subprocessRunner: runner, printer: PrinterMock())
        let pipeline = makePipeline(tasks: [makeTask(name: "Build", command: "swift build")])
        await #expect(throws: PipelineRunner.PipelineRunnerError.taskFailed(taskName: "Build", exitCode: 1)) {
            try await sut.run(pipeline, currentDirectoryURL: invocationDir)
        }
    }

    @Test
    func test_run_taskFails_stopsExecution() async throws {
        let runner = SubprocessRunnerMock()
        runner.exitCodes = [1, 0]
        let sut = PipelineRunner(subprocessRunner: runner, printer: PrinterMock())
        let pipeline = makePipeline(tasks: [
            makeTask(name: "First", command: "fail"),
            makeTask(name: "Second", command: "never-runs")
        ])
        do {
            try await sut.run(pipeline, currentDirectoryURL: invocationDir)
            Issue.record("Expected throw")
        } catch {
            #expect(runner.recordedArguments.count == 1)
        }
    }

    @Test
    func test_run_continueOnError_doesNotThrow() async throws {
        let runner = SubprocessRunnerMock()
        runner.exitCodes = [1, 0]
        let sut = PipelineRunner(subprocessRunner: runner, printer: PrinterMock())
        let pipeline = makePipeline(tasks: [
            makeTask(name: "Optional", command: "might-fail", continueOnError: true),
            makeTask(name: "Required", command: "must-run")
        ])
        try await sut.run(pipeline, currentDirectoryURL: invocationDir)
        #expect(runner.recordedArguments.count == 2)
    }

    // MARK: - Error descriptions

    @Test
    func test_errorDescription_taskFailed_containsNameAndCode() {
        let error = PipelineRunner.PipelineRunnerError.taskFailed(taskName: "Build", exitCode: 127)
        let description = error.errorDescription ?? ""
        #expect(description.contains("Build"))
        #expect(description.contains("127"))
    }

    // MARK: - Helpers

    private func makePipeline(
        tasks: [PipelineTask],
        env: [String: String]? = nil,
        workingDirectory: String? = nil
    ) -> Pipeline {
        Pipeline(tasks: tasks, env: env, workingDirectory: workingDirectory)
    }

    private func makeTask(
        name: String = "Task",
        command: String,
        env: [String: String]? = nil,
        continueOnError: Bool? = nil,
        workingDirectory: String? = nil
    ) -> PipelineTask {
        PipelineTask(name: name, command: command, tools: nil, env: env, continueOnError: continueOnError, workingDirectory: workingDirectory)
    }
}
