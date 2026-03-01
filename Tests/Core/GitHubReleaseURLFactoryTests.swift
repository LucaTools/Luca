//  GitHubReleaseURLFactoryTests.swift

import Foundation
import Testing
@testable import LucaCore

struct GitHubReleaseURLFactoryTests {
    
    @Test
    func makeReleaseAssetURL_returnsCorrectURL() throws {
        // Given
        let sut = GitHubReleaseURLFactory()
        let release = Release(organization: "testorg", repository: "testrepo", version: "1.0.0")
        let assetName = "testasset.zip"
        
        // When
        let url = try sut.makeReleaseAssetURL(release: release, asset: assetName)
        
        // Then
        #expect(url.absoluteString == "https://github.com/testorg/testrepo/releases/download/1.0.0/testasset.zip")
    }
    
    @Test
    func makeApiReleaseURL_returnsCorrectURL() throws {
        // Given
        let sut = GitHubReleaseURLFactory()
        let release = Release(organization: "testorg", repository: "testrepo", version: "1.0.0")

        // When
        let url = try sut.makeApiReleaseURL(release: release)

        // Then
        #expect(url.absoluteString == "https://api.github.com/repos/testorg/testrepo/releases/tags/1.0.0")
    }
}
