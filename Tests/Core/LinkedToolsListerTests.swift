//  LinkedToolsListerTests.swift

import Foundation
import Testing
@testable import LucaCore

struct LinkedToolsListerTests {
    
    @Test
    func listLinkedTools_noActiveFolder() throws {
        let fileManager = FileManagerWrapperMock()
        let lister = LinkedToolsLister(fileManager: fileManager)
        
        let linkedTools = try lister.linkedTools()
        #expect(linkedTools.isEmpty)
    }
    
    @Test
    func listLinkedTools_emptyActiveFolder() throws {
        let fileManager = FileManagerWrapperMock()
        let lister = LinkedToolsLister(fileManager: fileManager)
        
        try fileManager.createDirectory(at: fileManager.activeFolder, withIntermediateDirectories: true)
        
        let linkedTools = try lister.linkedTools()
        #expect(linkedTools.isEmpty)
    }
    
    @Test
    func listLinkedTools_success() throws {
        let fileManager = FileManagerWrapperMock()
        let lister = LinkedToolsLister(fileManager: fileManager)
        
        // Setup tools
        let toolName = "MyTool"
        let version = "1.0.0"
        let binaryName = "mytool"
        
        let toolFolder = fileManager.toolsFolder.appending(component: toolName).appending(component: version)
        let binaryURL = toolFolder.appending(component: "bin").appending(component: binaryName)
        
        try fileManager.createDirectory(at: binaryURL.deletingLastPathComponent(), withIntermediateDirectories: true)
        _ = fileManager.fileManager.createFile(atPath: binaryURL.path, contents: nil)
        
        // Setup tools folder and symlink
        try fileManager.createDirectory(at: fileManager.activeFolder, withIntermediateDirectories: true)
        let symlinkURL = fileManager.activeFolder.appending(component: binaryName)
        
        try fileManager.createSymbolicLink(at: symlinkURL, withDestinationURL: binaryURL)
        
        let linkedTools = try lister.linkedTools()
        
        #expect(linkedTools.count == 1)
        let tool = linkedTools.first!
        #expect(tool.name == toolName)
        #expect(tool.version == version)
        #expect(tool.binaryName == binaryName)
        #expect(tool.path == binaryURL.path)
    }
    
    @Test
    func listLinkedTools_ignoresNonSymlinks() throws {
        let fileManager = FileManagerWrapperMock()
        let lister = LinkedToolsLister(fileManager: fileManager)
        
        try fileManager.createDirectory(at: fileManager.activeFolder, withIntermediateDirectories: true)
        let fileURL = fileManager.activeFolder.appending(component: "regularFile")
        _ = fileManager.fileManager.createFile(atPath: fileURL.path, contents: nil)
        
        let linkedTools = try lister.linkedTools()
        #expect(linkedTools.isEmpty)
    }
    
    @Test
    func listLinkedTools_ignoresSymlinksOutsideToolsFolder() throws {
        let fileManager = FileManagerWrapperMock()
        let lister = LinkedToolsLister(fileManager: fileManager)
        
        try fileManager.createDirectory(at: fileManager.activeFolder, withIntermediateDirectories: true)
        
        let externalFile = fileManager.fileManager.temporaryDirectory.appending(component: "external")
        _ = fileManager.fileManager.createFile(atPath: externalFile.path, contents: nil)
        
        let symlinkURL = fileManager.activeFolder.appending(component: "externalLink")
        try fileManager.createSymbolicLink(at: symlinkURL, withDestinationURL: externalFile)
        
        let linkedTools = try lister.linkedTools()
        #expect(linkedTools.isEmpty)
    }
}
