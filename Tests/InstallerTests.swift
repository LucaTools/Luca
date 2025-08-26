//  InstallerTests.swift

import XCTest
@testable import LucaCore

class InstallerTests: XCTestCase {

    private let fileManager = MyFileManager()
    private lazy var cleaner = Cleaner(fileManager: fileManager)
    private var toolsFolder: URL!
    private var activeFolder: URL!
    
    override func setUp() async throws {
        try await super.setUp()
        try cleaner.clean()
        
        toolsFolder = fileManager.homeDirectoryForCurrentUser
            .appending(components: Constants.toolFolder, Constants.toolsFolder)
        try fileManager.createDirectory(at: toolsFolder, withIntermediateDirectories: true)

        activeFolder = URL(string: fileManager.currentDirectoryPath)!
            .appending(components: Constants.toolFolder, Constants.activeFolder)
        try fileManager.createDirectory(at: activeFolder, withIntermediateDirectories: true)
    }
    
    override func tearDown() async throws {
        toolsFolder = nil
        activeFolder = nil
        try cleaner.clean()
        try await super.tearDown()
    }
    
    func test_install() async throws {
        let spec = makeSpec()

        let toolBinaryPath = toolsFolder
            .appending(component: tool.name)
            .appending(components: tool.version, tool.binaryPath)
        let toolSymLink = activeFolder
            .appending(component: tool.binaryName)

        XCTAssertFalse(fileManager.fileExists(atPath: toolBinaryPath.path))
        XCTAssertFalse(fileManager.fileExists(atPath: toolSymLink.path))

        let installer = Installer(fileManager: fileManager)
        try await installer.install(from: spec)

        XCTAssertTrue(fileManager.fileExists(atPath: toolBinaryPath.path))
        XCTAssertTrue(fileManager.fileExists(atPath: toolSymLink.path))
        
        let expectedToolSymlinkDestination = fileManager.homeDirectoryForCurrentUser
            .appending(components:
                Constants.toolFolder,
                Constants.toolsFolder,
                tool.name,
                tool.version,
                tool.binaryPath
            )

        let externalToolSymlinkDestination = try fileManager.destinationOfSymbolicLink(atPath: toolSymLink.path)
        
        XCTAssertEqual(externalToolSymlinkDestination, expectedToolSymlinkDestination.path)
    }

    func test_installToolUpgradeVersion() async throws {
        let lowerVersionTool = Tool(
            name: "SwiftLint",
            binaryPath: "swiftlint",
            version: "0.52.0",
            zipUrl: "https://github.com/realm/SwiftLint/releases/download/0.52.0/portable_swiftlint.zip"
        )
        let higherVersionTool = Tool(
            name: "SwiftLint",
            binaryPath: "swiftlint",
            version: "0.53.0",
            zipUrl: "https://github.com/realm/SwiftLint/releases/download/0.53.0/portable_swiftlint.zip"
        )

        let lowerVersionSpecs = Spec(tools: [lowerVersionTool], version: "0.0.1")
        let higherVersionSpecs = Spec(tools: [higherVersionTool], version: "0.0.1")

        let installer = Installer(fileManager: fileManager)

        try await installer.install(from: lowerVersionSpecs)
        try await installer.install(from: higherVersionSpecs)

        let higherVersionToolSymlink = activeFolder
            .appending(component: higherVersionTool.binaryPath)
        
        let expectedHigherVersionToolSymlinkDestination = fileManager.homeDirectoryForCurrentUser
            .appending(components:
                Constants.toolFolder,
                Constants.toolsFolder,
                higherVersionTool.name,
                higherVersionTool.version,
                higherVersionTool.binaryPath
            )

        let higherVersionToolSymlinkDestination = try fileManager.destinationOfSymbolicLink(atPath: higherVersionToolSymlink.path)

        XCTAssertEqual(higherVersionToolSymlinkDestination, expectedHigherVersionToolSymlinkDestination.path)
    }
    
    func test_installToolDowngradeVersion() async throws {
        let lowerVersionTool = Tool(
            name: "SwiftLint",
            binaryPath: "swiftlint",
            version: "0.52.0",
            zipUrl: "https://github.com/realm/SwiftLint/releases/download/0.52.0/portable_swiftlint.zip"
        )
        let higherVersionTool = Tool(
            name: "SwiftLint",
            binaryPath: "swiftlint",
            version: "0.53.0",
            zipUrl: "https://github.com/realm/SwiftLint/releases/download/0.53.0/portable_swiftlint.zip"
        )

        let lowerVersionSpecs = Spec(tools: [lowerVersionTool], version: "0.0.1")
        let higherVersionSpecs = Spec(tools: [higherVersionTool], version: "0.0.1")

        let installer = Installer(fileManager: fileManager)

        try await installer.install(from: higherVersionSpecs)
        try await installer.install(from: lowerVersionSpecs)

        let lowerVersionToolSymlink = activeFolder
            .appending(component: lowerVersionTool.binaryPath)
        
        let expectedLowerVersionToolSymlinkDestination = fileManager.homeDirectoryForCurrentUser
            .appending(components:
                Constants.toolFolder,
                Constants.toolsFolder,
                lowerVersionTool.name,
                lowerVersionTool.version,
                lowerVersionTool.binaryPath
            )

        let lowerVersionToolSymlinkDestination = try fileManager.destinationOfSymbolicLink(atPath: lowerVersionToolSymlink.path)

        XCTAssertEqual(lowerVersionToolSymlinkDestination, expectedLowerVersionToolSymlinkDestination.path)
    }
    
    // MARK: - Private
    
    private func makeEmptySpec() -> Spec {
        Spec(tools: [], version: "0.0.1")
    }

    private func makeSpec() -> Spec {
        Spec(tools: [tool], version: "0.0.1")
    }

    private var tool: Tool = Tool(
        name: "Sourcery",
        binaryPath: "bin/sourcery",
        version: "2.2.5",
        zipUrl: "https://github.com/krzysztofzablocki/Sourcery/releases/download/2.2.5/sourcery-2.2.5.zip"
    )
}
