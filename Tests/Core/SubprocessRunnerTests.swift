//  SubprocessRunnerTests.swift

import Foundation
import Testing
@testable import LucaCore

struct SubprocessRunnerTests {

    private let sh = URL(fileURLWithPath: "/bin/sh")
    private let runner = SubprocessRunner()

    // MARK: - Exit codes

    @Test
    func test_run_exitZero_returnsZero() async throws {
        let status = try await runner.run(executableURL: sh, arguments: ["-c", "exit 0"])
        #expect(status == 0)
    }

    @Test
    func test_run_exitOne_returnsOne() async throws {
        let status = try await runner.run(executableURL: sh, arguments: ["-c", "exit 1"])
        #expect(status == 1)
    }

    @Test
    func test_run_customExitCode_returnsExactCode() async throws {
        let status = try await runner.run(executableURL: sh, arguments: ["-c", "exit 42"])
        #expect(status == 42)
    }

    // MARK: - Arguments

    @Test
    func test_run_argumentsArePassedToProcess() async throws {
        // `test -n "hello"` exits 0 when the string is non-empty
        let status = try await runner.run(executableURL: sh, arguments: ["-c", "test -n \"$1\"", "--", "hello"])
        #expect(status == 0)
    }

    // MARK: - stdin behaviour

    @Test
    func test_run_stdinIsClosed_catExitsImmediately() async throws {
        // With stdin set to /dev/null, `cat` reads EOF and exits 0 without blocking.
        let status = try await runner.run(executableURL: sh, arguments: ["-c", "cat"])
        #expect(status == 0)
    }

    // MARK: - Environment

    @Test
    func test_run_environmentVariablesAreMergedIntoProcess() async throws {
        // The subprocess should see the custom environment variable
        let status = try await runner.run(
            executableURL: sh,
            arguments: ["-c", "test \"$MY_TEST_VAR\" = \"hello\""],
            environment: ["MY_TEST_VAR": "hello"]
        )
        #expect(status == 0)
    }

    @Test
    func test_run_emptyEnvironment_inheritsParentEnvironment() async throws {
        // With empty environment, the process inherits the parent's environment
        let status = try await runner.run(
            executableURL: sh,
            arguments: ["-c", "test -n \"$PATH\""],
            environment: [:]
        )
        #expect(status == 0)
    }

    // MARK: - Invalid executable

    @Test
    func test_run_nonExistentExecutable_throws() async throws {
        let missing = URL(fileURLWithPath: "/nonexistent/binary")
        await #expect(throws: (any Error).self) {
            _ = try await runner.run(executableURL: missing, arguments: [])
        }
    }
}
