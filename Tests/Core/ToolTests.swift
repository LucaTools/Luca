//  ToolTests.swift

import Foundation
import Testing
@testable import LucaCore

struct ToolTests {

    private func makeTool(
        name: String = "ToolName",
        binaryPath: String? = nil,
        desiredBinaryName: String? = nil,
        ignoreArchCheck: Bool? = nil
    ) -> Tool {
        Tool(
            name: name,
            version: "1.0.0",
            url: URL(string: "https://example.com/tool.zip")!,
            binaryPath: binaryPath,
            desiredBinaryName: desiredBinaryName,
            checksum: nil,
            algorithm: nil,
            ignoreArchCheck: ignoreArchCheck
        )
    }

    // MARK: - expectedBinaryName

    @Test
    func test_expectedBinaryName_desiredBinaryNameSet() {
        let tool = makeTool(binaryPath: "bin/tool", desiredBinaryName: "mytool")

        #expect(tool.expectedBinaryName == "mytool")
    }

    @Test
    func test_expectedBinaryName_binaryPathSet_noDesiredName() {
        let tool = makeTool(binaryPath: "bin/tool")

        #expect(tool.expectedBinaryName == "tool")
    }

    @Test
    func test_expectedBinaryName_onlyNameSet() {
        let tool = makeTool()

        #expect(tool.expectedBinaryName == "ToolName")
    }

    // MARK: - effectiveBinaryPath

    @Test
    func test_effectiveBinaryPath_desiredBinaryNameSet() {
        let tool = makeTool(binaryPath: "bin/tool", desiredBinaryName: "mytool")

        #expect(tool.effectiveBinaryPath == "mytool")
    }

    @Test
    func test_effectiveBinaryPath_binaryPathSet_noDesiredName() {
        let tool = makeTool(binaryPath: "bin/tool")

        #expect(tool.effectiveBinaryPath == "bin/tool")
    }

    @Test
    func test_effectiveBinaryPath_onlyNameSet() {
        let tool = makeTool()

        #expect(tool.effectiveBinaryPath == "ToolName")
    }

    @Test
    func test_effectiveBinaryPath_allSet_desiredBinaryNameWins() {
        let tool = makeTool(binaryPath: "bin/tool", desiredBinaryName: "mytool")

        #expect(tool.effectiveBinaryPath == "mytool")
    }
}
