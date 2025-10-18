//  ToolFactoryTests.swift

import Foundation
import Testing
import Yams
@testable import LucaCore

struct ToolFactoryTests {
    
    private let fileManager = FileManager.default    
    
    @Test(arguments: ["Lucafile", "CustomSpec.json"])
    func spec(filename: String) async throws {
        let urlFactory = GitHubReleaseURLFactory()
        let toggleGenUrl = try urlFactory.makeReleaseAssetURL(
            release: Release(organization: "TogglesPlatform", repository: "ToggleGen", version: "1.0.0"),
            asset: "ToggleGen-macOS-universal-binary.zip"
        )
        let sourceryUrl = try urlFactory.makeReleaseAssetURL(
            release: Release(organization: "krzysztofzablocki", repository: "Sourcery", version: "2.2.7"),
            asset: "sourcery-2.2.7.zip"
        )
        
        let spec = Spec(tools: [
            Tool(name: "ToggleGen", version: "1.0.0", url: toggleGenUrl, binaryPath: nil, checksum: nil, algorithm: nil),
            Tool(name: "Sourcery", version: "2.2.7", url: sourceryUrl, binaryPath: "bin/sourcery", checksum: nil, algorithm: nil)
        ])
        
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
        
        #expect(firstTool.name == "ToggleGen")
        #expect(firstTool.version == "1.0.0")
        #expect(firstTool.url == toggleGenUrl)
        #expect(firstTool.binaryPath == nil)
        
        #expect(secondTool.name == "Sourcery")
        #expect(secondTool.version == "2.2.7")
        #expect(secondTool.url == sourceryUrl)
        #expect(secondTool.binaryPath == "bin/sourcery")
    }
    
    @Test
    func individual_valid() async throws {
        let asset = "ToggleGen-macOS.zip"
        
        let dataDownloader = DataDownloaderMock(result: .fixture(Fixture(filename: "ToggleGenReleaseInfo", type: "json")))
        let releaseInfoProvider = ReleaseInfoProvider(dataDownloader: dataDownloader)
        
        let specLoader = SpecLoader(fileManager: fileManager)
        let sut = ToolFactory(releaseInfoProvider: releaseInfoProvider, specLoader: specLoader)
        
        let tools = try await sut.toolsForInstallationType(
            .individual(
                identifier: "TogglesPlatform/ToggleGen@1.0.0",
                asset: nil,
                binaryPath: nil,
                checksum: nil,
                algorithm: nil
            )
        )
        #expect(tools.count == 1)
        
        let urlFactory = GitHubReleaseURLFactory()
        let toggleGenUrl = try urlFactory.makeReleaseAssetURL(
            release: Release(organization: "TogglesPlatform", repository: "ToggleGen", version: "1.0.0"),
            asset: asset
        )
        
        let tool = try #require(tools.first)
        #expect(tool.name == "ToggleGen")
        #expect(tool.version == "1.0.0")
        #expect(tool.url == toggleGenUrl)
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
                identifier: "TogglesPlatform/ToggleGen@1.0.0",
                asset: asset,
                binaryPath: nil,
                checksum: nil,
                algorithm: nil
            )
        )
        #expect(tools.count == 1)
        
        let urlFactory = GitHubReleaseURLFactory()
        let toggleGenUrl = try urlFactory.makeReleaseAssetURL(
            release: Release(organization: "TogglesPlatform", repository: "ToggleGen", version: "1.0.0"),
            asset: asset
        )
        
        let tool = try #require(tools.first)
        #expect(tool.name == "ToggleGen")
        #expect(tool.version == "1.0.0")
        #expect(tool.url == toggleGenUrl)
        #expect(tool.binaryPath == nil)
    }
    
    @Test
    func individual_valid_asset_binaryPath() async throws {
        let asset = "mock-asset.zip"
        let binaryPath = "bin/togglegen"
        
        let dataDownloader = DataDownloader(session: .shared)
        let releaseInfoProvider = ReleaseInfoProvider(dataDownloader: dataDownloader)
        
        let specLoader = SpecLoader(fileManager: fileManager)
        let sut = ToolFactory(releaseInfoProvider: releaseInfoProvider, specLoader: specLoader)
        
        let tools = try await sut.toolsForInstallationType(
            .individual(
                identifier: "TogglesPlatform/ToggleGen@1.0.0",
                asset: asset,
                binaryPath: binaryPath,
                checksum: nil,
                algorithm: nil
            )
        )
        #expect(tools.count == 1)
        
        let urlFactory = GitHubReleaseURLFactory()
        let toggleGenUrl = try urlFactory.makeReleaseAssetURL(
            release: Release(organization: "TogglesPlatform", repository: "ToggleGen", version: "1.0.0"),
            asset: asset
        )
        
        let tool = try #require(tools.first)
        #expect(tool.name == "ToggleGen")
        #expect(tool.version == "1.0.0")
        #expect(tool.url == toggleGenUrl)
        #expect(tool.binaryPath == binaryPath)
    }
    
    @Test
    func individual_invalidIdentifier() async throws {
        let dataDownloader = DataDownloader(session: .shared)
        let releaseInfoProvider = ReleaseInfoProvider(dataDownloader: dataDownloader)
        
        let specLoader = SpecLoader(fileManager: fileManager)
        let sut = ToolFactory(releaseInfoProvider: releaseInfoProvider, specLoader: specLoader)
            
        await #expect(throws: ToolFactory.ToolFactoryError.invalidIdentifierFormat("TogglesPlatform/ToggleGen")) {
            _ = try await sut
                .toolsForInstallationType(
                    .individual(
                        identifier: "TogglesPlatform/ToggleGen",
                        asset: nil,
                        binaryPath: nil,
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
        
        await #expect(throws: ToolFactory.ToolFactoryError.invalidRepositoryFormat("ToggleGen")) {
            _ = try await sut
                .toolsForInstallationType(
                    .individual(
                        identifier: "ToggleGen@1.0.0",
                        asset: nil,
                        binaryPath: nil,
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
        let name = "ToggleGen"
        let version = "1.0.0"
        
        let urlFactory = GitHubReleaseURLFactory()
        let toggleGenUrl = try urlFactory.makeReleaseAssetURL(
            release: Release(organization: "TogglesPlatform", repository: "ToggleGen", version: "1.0.0"),
            asset: "ToggleGen-macOS-universal-binary.zip"
        )
        
        let tools = try await sut.toolsForInstallationType(
            .individualInline(
                name: name,
                version: version,
                url: toggleGenUrl,
                binaryPath: nil,
                checksum: nil,
                algorithm: nil
            )
        )
        #expect(tools.count == 1)
        
        let tool = try #require(tools.first)
        #expect(tool.name == name)
        #expect(tool.version == version)
        #expect(tool.url == toggleGenUrl)
        #expect(tool.binaryPath == nil)
    }
    
    @Test
    func individualInline_binaryPath() async throws {
        let dataDownloader = DataDownloader(session: .shared)
        let releaseInfoProvider = ReleaseInfoProvider(dataDownloader: dataDownloader)
        
        let specLoader = SpecLoader(fileManager: fileManager)
        let sut = ToolFactory(releaseInfoProvider: releaseInfoProvider, specLoader: specLoader)
        let name = "ToggleGen"
        let version = "1.0.0"
        
        let urlFactory = GitHubReleaseURLFactory()
        let toggleGenUrl = try urlFactory.makeReleaseAssetURL(
            release: Release(organization: "TogglesPlatform", repository: "ToggleGen", version: "1.0.0"),
            asset: "ToggleGen-macOS-universal-binary.zip"
        )
        
        let binaryPath = "bin/togglegen"
            
        let tools = try await sut.toolsForInstallationType(
            .individualInline(
                name: name,
                version: version,
                url: toggleGenUrl,
                binaryPath: binaryPath,
                checksum: nil,
                algorithm: nil
            )
        )
        #expect(tools.count == 1)
        
        let tool = try #require(tools.first)
        #expect(tool.name == name)
        #expect(tool.version == version)
        #expect(tool.url == toggleGenUrl)
        #expect(tool.binaryPath == binaryPath)
    }
}
