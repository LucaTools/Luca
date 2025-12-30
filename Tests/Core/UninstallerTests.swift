import Foundation
import Testing
@testable import LucaCore

struct UninstallerTests {
    
    @Test
    func uninstall_success() throws {
        let fileManager = FileManagerWrapperMock()
        let uninstaller = Uninstaller(fileManager: fileManager)
        
        let toolName = "MyTool"
        let version = "1.0.0"
        
        let versionFolder = fileManager.toolsFolder
            .appending(component: toolName)
            .appending(component: version)
        
        try fileManager.createDirectory(at: versionFolder, withIntermediateDirectories: true)
        
        #expect(fileManager.fileExists(atPath: versionFolder.path))
        
        try uninstaller.uninstall(tool: toolName, version: version)
        
        #expect(!fileManager.fileExists(atPath: versionFolder.path))
    }
    
    @Test
    func uninstall_versionNotFound() throws {
        let fileManager = FileManagerWrapperMock()
        let uninstaller = Uninstaller(fileManager: fileManager)
        
        let toolName = "MyTool"
        let version = "1.0.0"
        
        #expect(throws: Uninstaller.UninstallerError.versionNotFound(tool: toolName, version: version)) {
            try uninstaller.uninstall(tool: toolName, version: version)
        }
    }
    
    @Test
    func uninstall_removesEmptyToolFolder() throws {
        let fileManager = FileManagerWrapperMock()
        let uninstaller = Uninstaller(fileManager: fileManager)
        
        let toolName = "MyTool"
        let version = "1.0.0"
        
        let toolFolder = fileManager.toolsFolder.appending(component: toolName)
        let versionFolder = toolFolder.appending(component: version)
        
        try fileManager.createDirectory(at: versionFolder, withIntermediateDirectories: true)
        
        try uninstaller.uninstall(tool: toolName, version: version)
        
        #expect(!fileManager.fileExists(atPath: toolFolder.path))
    }
    
    @Test
    func uninstall_keepsNonEmptyToolFolder() throws {
        let fileManager = FileManagerWrapperMock()
        let uninstaller = Uninstaller(fileManager: fileManager)
        
        let toolName = "MyTool"
        let version1 = "1.0.0"
        let version2 = "2.0.0"
        
        let toolFolder = fileManager.toolsFolder.appending(component: toolName)
        let version1Folder = toolFolder.appending(component: version1)
        let version2Folder = toolFolder.appending(component: version2)
        
        try fileManager.createDirectory(at: version1Folder, withIntermediateDirectories: true)
        try fileManager.createDirectory(at: version2Folder, withIntermediateDirectories: true)
        
        try uninstaller.uninstall(tool: toolName, version: version1)
        
        #expect(!fileManager.fileExists(atPath: version1Folder.path))
        #expect(fileManager.fileExists(atPath: version2Folder.path))
        #expect(fileManager.fileExists(atPath: toolFolder.path))
    }
}
