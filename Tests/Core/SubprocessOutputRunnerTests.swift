//  SubprocessOutputRunnerTests.swift

import Foundation
import Testing
@testable import LucaFoundation

struct SubprocessOutputRunnerTests {

    private let sh = URL(fileURLWithPath: "/bin/sh")
    private let runner = SubprocessOutputRunner()

    @Test
    func test_run_capturesStdout() async throws {
        let result = try await runner.run(executableURL: sh, arguments: ["-c", "echo hello"], environment: [:])
        #expect(result.exitCode == 0)
        #expect(result.output.trimmingCharacters(in: .whitespacesAndNewlines) == "hello")
    }

    @Test
    func test_run_multilineStdout_capturesAllLines() async throws {
        let result = try await runner.run(executableURL: sh, arguments: ["-c", "printf 'line1\\nline2\\n'"], environment: [:])
        #expect(result.output == "line1\nline2\n")
    }

    @Test
    func test_run_nonZeroExit_returnsExitCodeWithoutThrowing() async throws {
        let result = try await runner.run(executableURL: sh, arguments: ["-c", "echo partial; exit 7"], environment: [:])
        #expect(result.exitCode == 7)
        #expect(result.output.trimmingCharacters(in: .whitespacesAndNewlines) == "partial")
    }

    @Test
    func test_run_environmentVariablesAreMergedIntoProcess() async throws {
        let result = try await runner.run(
            executableURL: sh,
            arguments: ["-c", "echo \"$MY_TEST_VAR\""],
            environment: ["MY_TEST_VAR": "hello"]
        )
        #expect(result.output.trimmingCharacters(in: .whitespacesAndNewlines) == "hello")
    }

    @Test
    func test_run_stdinIsClosed_catExitsImmediately() async throws {
        let result = try await runner.run(executableURL: sh, arguments: ["-c", "cat"], environment: [:])
        #expect(result.exitCode == 0)
    }
}
