//  InstalledToolsListerTests.swift

import Foundation
import Testing
@testable import LucaCore

struct InstalledToolsListerTests {
    
    @Test
    func listInstalledTools_noToolsFolder() throws {
        let fileManager = FileManagerWrapperMock()
        let lister = InstalledToolsLister(fileManager: fileManager)
        
        // Ensure tools folder does not exist (mock uses temp dir which is empty initially)
        
        let installedTools = try lister.installedTools()
        #expect(installedTools.isEmpty)
    }
    
    @Test
    func listInstalledTools_emptyToolsFolder() throws {
        let fileManager = FileManagerWrapperMock()
        let lister = InstalledToolsLister(fileManager: fileManager)
        
        try fileManager.createDirectory(at: fileManager.toolsFolder, withIntermediateDirectories: true)
        
        let installedTools = try lister.installedTools()
        #expect(installedTools.isEmpty)
    }
    
    @Test
    func listInstalledTools_success() throws {
        let fileManager = FileManagerWrapperMock()
        let lister = InstalledToolsLister(fileManager: fileManager)
        
        let tools = [
            "ToolA": ["1.0.0", "1.1.0"],
            "ToolB": ["2.0.0"]
        ]
        
        for (tool, versions) in tools {
            let toolFolder = fileManager.toolsFolder.appending(component: tool)
            try fileManager.createDirectory(at: toolFolder, withIntermediateDirectories: true)
            
            for version in versions {
                let versionFolder = toolFolder.appending(component: version)
                try fileManager.createDirectory(at: versionFolder, withIntermediateDirectories: true)
            }
        }
        
        let installedTools = try lister.installedTools()

        #expect(installedTools.count == 2)
        #expect(installedTools["ToolA"]?.sorted() == ["1.0.0", "1.1.0"])
        #expect(installedTools["ToolB"] == ["2.0.0"])
    }

    @Test
    func listInstalledTools_nonDirectoryItemsAreSkipped() throws {
        let fileManager = FileManagerWrapperMock()
        let lister = InstalledToolsLister(fileManager: fileManager)

        try fileManager.createDirectory(at: fileManager.toolsFolder, withIntermediateDirectories: true)

        // Place a regular file inside the tools folder (should be silently skipped)
        let filePath = fileManager.toolsFolder.appending(component: "not-a-tool.txt").path
        _ = FileManager.default.createFile(atPath: filePath, contents: Data("content".utf8))

        // Create a valid tool directory alongside the file
        let toolFolder = fileManager.toolsFolder.appending(component: "ValidTool")
        try fileManager.createDirectory(at: toolFolder, withIntermediateDirectories: true)
        let versionFolder = toolFolder.appending(component: "1.0.0")
        try fileManager.createDirectory(at: versionFolder, withIntermediateDirectories: true)

        let installedTools = try lister.installedTools()

        #expect(installedTools.count == 1)
        #expect(installedTools["ValidTool"] == ["1.0.0"])
    }
}
