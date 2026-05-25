//  ToolFactoryTests.swift

import Foundation
import Testing
import Yams
@testable import LucaFoundation
@testable import ManagerCore

struct ToolFactoryTests {

    private let fileManager = FileManager.default

    @Test(arguments: ["Lucafile", "CustomSpec.json"])
    func spec(filename: String) async throws {
        let urlFactory = GitHubReleaseURLFactory()
        let mockToolUrl = try urlFactory.makeReleaseAssetURL(
            release: Release(organization: "organization", repository: "MockTool", version: "1.0.0"),
            asset: "tool-macOS-universal-binary.zip"
        )
        let sourceryUrl = try urlFactory.makeReleaseAssetURL(
            release: Release(organization: "krzysztofzablocki", repository: "Sourcery", version: "2.2.7"),
            asset: "sourcery-2.2.7.zip"
        )

        let spec = Spec(tools: [
            Tool(name: "MockTool", version: "1.0.0", url: mockToolUrl, binaryPath: nil, desiredBinaryName: nil, checksum: nil, algorithm: nil, ignoreArchCheck: nil),
            Tool(name: "Sourcery", version: "2.2.7", url: sourceryUrl, binaryPath: "bin/sourcery", desiredBinaryName: nil, checksum: nil, algorithm: nil, ignoreArchCheck: nil)
        ], skills: nil, agents: nil)

        let specString = try YAMLEncoder().encode(spec)
        let specPath = fileManager.temporaryDirectory.appending(component: UUID().uuidString).appending(component: filename)

        #expect(throws: Never.self) {
            try fileManager.createDirectory(at: specPath.deletingLastPathComponent(), withIntermediateDirectories: true)
        }

        let specData = Data(specString.utf8)
        #expect(fileManager.createFile(atPath: specPath.path, contents: specData))

        let dataDownloader = DataDownloader(session: .shared)
        let releaseInfoProvider = ReleaseInfoProvider(dataDownloader: dataDownloader)

        let specLoader = SpecLoader(fileManager: fileManager)
        let sut = ToolFactory(releaseInfoProvider: releaseInfoProvider, specLoader: specLoader)

        let tools = try await sut.toolsForInstallationType(.spec(specPath: specPath))
        #expect(tools.count == 2)

        let firstTool = try #require(tools.first)
        let secondTool = try #require(tools.last)

        #expect(firstTool.name == "MockTool")
        #expect(firstTool.version == "1.0.0")
        #expect(firstTool.url == mockToolUrl)
        #expect(firstTool.binaryPath == nil)

        #expect(secondTool.name == "Sourcery")
        #expect(secondTool.version == "2.2.7")
        #expect(secondTool.url == sourceryUrl)
        #expect(secondTool.binaryPath == "bin/sourcery")
    }

    @Test
    func individual_valid() async throws {
        #if os(Linux)
        let asset = "tool-Linux.zip"
        #else
        let asset = "tool-macOS.zip"
        #endif

        let dataDownloader = DataDownloaderMock(result: .fixture(Fixture(filename: "ReleaseInfo", type: "json")))
        let releaseInfoProvider = ReleaseInfoProvider(dataDownloader: dataDownloader)

        let specLoader = SpecLoader(fileManager: fileManager)
        let sut = ToolFactory(releaseInfoProvider: releaseInfoProvider, specLoader: specLoader)

        let tools = try await sut.toolsForInstallationType(
            .individual(
                identifier: "organization/repository@1.0.0",
                asset: nil,
                binaryPath: nil,
                desiredBinaryName: nil,
                checksum: nil,
                algorithm: nil
            )
        )
        #expect(tools.count == 1)

        let urlFactory = GitHubReleaseURLFactory()
        let url = try urlFactory.makeReleaseAssetURL(
            release: Release(organization: "organization", repository: "repository", version: "1.0.0"),
            asset: asset
        )

        let tool = try #require(tools.first)
        #expect(tool.name == "repository")
        #expect(tool.version == "1.0.0")
        #expect(tool.url == url)
        #expect(tool.binaryPath == nil)
    }

    @Test
    func individual_valid_asset() async throws {
        let asset = "mock-asset.zip"

        let dataDownloader = DataDownloader(session: .shared)
        let releaseInfoProvider = ReleaseInfoProvider(dataDownloader: dataDownloader)

        let specLoader = SpecLoader(fileManager: fileManager)
        let sut = ToolFactory(releaseInfoProvider: releaseInfoProvider, specLoader: specLoader)

        let tools = try await sut.toolsForInstallationType(
            .individual(
                identifier: "organization/repository@1.0.0",
                asset: asset,
                binaryPath: nil,
                desiredBinaryName: nil,
                checksum: nil,
                algorithm: nil
            )
        )
        #expect(tools.count == 1)

        let urlFactory = GitHubReleaseURLFactory()
        let url = try urlFactory.makeReleaseAssetURL(
            release: Release(organization: "organization", repository: "repository", version: "1.0.0"),
            asset: asset
        )

        let tool = try #require(tools.first)
        #expect(tool.name == "repository")
        #expect(tool.version == "1.0.0")
        #expect(tool.url == url)
        #expect(tool.binaryPath == nil)
    }

    @Test
    func individual_valid_asset_binaryPath() async throws {
        let asset = "mock-asset.zip"
        let binaryPath = "bin/tool"

        let dataDownloader = DataDownloader(session: .shared)
        let releaseInfoProvider = ReleaseInfoProvider(dataDownloader: dataDownloader)

        let specLoader = SpecLoader(fileManager: fileManager)
        let sut = ToolFactory(releaseInfoProvider: releaseInfoProvider, specLoader: specLoader)

        let tools = try await sut.toolsForInstallationType(
            .individual(
                identifier: "organization/repository@1.0.0",
                asset: asset,
                binaryPath: binaryPath,
                desiredBinaryName: nil,
                checksum: nil,
                algorithm: nil
            )
        )
        #expect(tools.count == 1)

        let urlFactory = GitHubReleaseURLFactory()
        let url = try urlFactory.makeReleaseAssetURL(
            release: Release(organization: "organization", repository: "repository", version: "1.0.0"),
            asset: asset
        )

        let tool = try #require(tools.first)
        #expect(tool.name == "repository")
        #expect(tool.version == "1.0.0")
        #expect(tool.url == url)
        #expect(tool.binaryPath == binaryPath)
    }

    @Test
    func individual_invalidIdentifier() async throws {
        let dataDownloader = DataDownloader(session: .shared)
        let releaseInfoProvider = ReleaseInfoProvider(dataDownloader: dataDownloader)

        let specLoader = SpecLoader(fileManager: fileManager)
        let sut = ToolFactory(releaseInfoProvider: releaseInfoProvider, specLoader: specLoader)

        await #expect(throws: ToolFactory.ToolFactoryError.invalidIdentifierFormat("organization/repository")) {
            _ = try await sut
                .toolsForInstallationType(
                    .individual(
                        identifier: "organization/repository",
                        asset: nil,
                        binaryPath: nil,
                        desiredBinaryName: nil,
                        checksum: nil,
                        algorithm: nil
                    )
                )
        }
    }

    @Test
    func individual_invalidRepository() async throws {
        let dataDownloader = DataDownloader(session: .shared)
        let releaseInfoProvider = ReleaseInfoProvider(dataDownloader: dataDownloader)

        let specLoader = SpecLoader(fileManager: fileManager)
        let sut = ToolFactory(releaseInfoProvider: releaseInfoProvider, specLoader: specLoader)

        await #expect(throws: ToolFactory.ToolFactoryError.invalidRepositoryFormat("repository")) {
            _ = try await sut
                .toolsForInstallationType(
                    .individual(
                        identifier: "repository@1.0.0",
                        asset: nil,
                        binaryPath: nil,
                        desiredBinaryName: nil,
                        checksum: nil,
                        algorithm: nil
                    )
                )
        }
    }

    @Test
    func individualInline() async throws {
        let dataDownloader = DataDownloader(session: .shared)
        let releaseInfoProvider = ReleaseInfoProvider(dataDownloader: dataDownloader)

        let specLoader = SpecLoader(fileManager: fileManager)
        let sut = ToolFactory(releaseInfoProvider: releaseInfoProvider, specLoader: specLoader)
        let name = "MockTool"
        let version = "1.0.0"

        let urlFactory = GitHubReleaseURLFactory()
        let mockToolUrl = try urlFactory.makeReleaseAssetURL(
            release: Release(organization: "organization", repository: "MockTool", version: "1.0.0"),
            asset: "tool-macOS-universal-binary.zip"
        )

        let tools = try await sut.toolsForInstallationType(
            .individualInline(
                name: name,
                version: version,
                url: mockToolUrl,
                binaryPath: nil,
                desiredBinaryName: nil,
                checksum: nil,
                algorithm: nil
            )
        )
        #expect(tools.count == 1)

        let tool = try #require(tools.first)
        #expect(tool.name == name)
        #expect(tool.version == version)
        #expect(tool.url == mockToolUrl)
        #expect(tool.binaryPath == nil)
    }

    @Test
    func individualInline_binaryPath() async throws {
        let dataDownloader = DataDownloader(session: .shared)
        let releaseInfoProvider = ReleaseInfoProvider(dataDownloader: dataDownloader)

        let specLoader = SpecLoader(fileManager: fileManager)
        let sut = ToolFactory(releaseInfoProvider: releaseInfoProvider, specLoader: specLoader)
        let name = "MockTool"
        let version = "1.0.0"

        let urlFactory = GitHubReleaseURLFactory()
        let mockToolUrl = try urlFactory.makeReleaseAssetURL(
            release: Release(organization: "organization", repository: "MockTool", version: "1.0.0"),
            asset: "tool-macOS-universal-binary.zip"
        )

        let binaryPath = "bin/tool"

        let tools = try await sut.toolsForInstallationType(
            .individualInline(
                name: name,
                version: version,
                url: mockToolUrl,
                binaryPath: binaryPath,
                desiredBinaryName: nil,
                checksum: nil,
                algorithm: nil
            )
        )
        #expect(tools.count == 1)

        let tool = try #require(tools.first)
        #expect(tool.name == name)
        #expect(tool.version == version)
        #expect(tool.url == mockToolUrl)
        #expect(tool.binaryPath == binaryPath)
    }
}
