import Foundation
import Testing
@testable import LucaCore

struct UnlinkerTests {
    
    @Test
    func unlink_success() throws {
        let fileManager = FileManagerWrapperMock()
        let unlinker = Unlinker(fileManager: fileManager)
        
        let symlinkName = "mytool"
        let symlinkFile = fileManager.activeFolder.appending(component: symlinkName)
        
        // Create a dummy file to simulate the symlink
        try fileManager.createDirectory(at: fileManager.activeFolder, withIntermediateDirectories: true)
        fileManager.fileManager.createFile(atPath: symlinkFile.path, contents: nil)
        
        #expect(fileManager.fileExists(atPath: symlinkFile.path))
        
        try unlinker.unlink(symlink: symlinkName)
        
        #expect(!fileManager.fileExists(atPath: symlinkFile.path))
    }
    
    @Test
    func unlink_symlinkNotFound() throws {
        let fileManager = FileManagerWrapperMock()
        let unlinker = Unlinker(fileManager: fileManager)
        
        let symlinkName = "nonexistent"
        
        #expect(throws: Unlinker.UninstallerError.symlinkNotFound(symlink: symlinkName)) {
            try unlinker.unlink(symlink: symlinkName)
        }
    }
}
