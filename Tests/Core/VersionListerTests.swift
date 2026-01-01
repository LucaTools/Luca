//  VersionListerTests.swift

import Foundation
import Testing
@testable import LucaCore

struct VersionListerTests {
    
    @Test
    func listVersions_toolNotFound() throws {
        let fileManager = FileManagerWrapperMock()
        let versionLister = VersionLister(fileManager: fileManager)
        
        #expect(throws: VersionLister.VersionListerError.toolNotFound(tool: "NonExistentTool")) {
            try versionLister.versions(for: "NonExistentTool")
        }
    }
    
    @Test
    func listVersions_success() throws {
        let fileManager = FileManagerWrapperMock()
        let versionLister = VersionLister(fileManager: fileManager)
        
        let toolName = "MyTool"
        let versions = ["1.0.0", "1.1.0", "2.0.0"]
        
        let toolFolder = fileManager.toolsFolder.appending(component: toolName)
        try fileManager.createDirectory(at: toolFolder, withIntermediateDirectories: true)
        
        for version in versions {
            let versionFolder = toolFolder.appending(component: version)
            try fileManager.createDirectory(at: versionFolder, withIntermediateDirectories: true)
        }
        
        let listedVersions = try versionLister.versions(for: toolName)
        
        #expect(listedVersions.sorted() == versions.sorted())
    }
}
