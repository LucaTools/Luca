import Foundation
import Testing
@testable import LucaCore

struct UnlinkerTests {
    
    @Test
    func unlink_success() throws {
        let fileManager = FileManagerWrapperMock()
        let unlinker = Unlinker(fileManager: fileManager, printer: PrinterMock())
        
        let symlinkName = "mytool"
        let symlinkFile = fileManager.symlinksFolder.appending(component: symlinkName)
        
        // Create a dummy file to simulate the symlink
        try fileManager.createDirectory(at: fileManager.symlinksFolder, withIntermediateDirectories: true)
        _ = fileManager.fileManager.createFile(atPath: symlinkFile.path, contents: nil)
        
        #expect(fileManager.fileExists(atPath: symlinkFile.path))
        
        try unlinker.unlink(symlink: symlinkName)
        
        #expect(!fileManager.fileExists(atPath: symlinkFile.path))
    }
    
    @Test
    func unlink_symlinkNotFound() throws {
        let fileManager = FileManagerWrapperMock()
        let unlinker = Unlinker(fileManager: fileManager, printer: PrinterMock())
        
        let symlinkName = "nonexistent"
        
        #expect(throws: Unlinker.UnlinkerError.symlinkNotFound(symlink: symlinkName)) {
            try unlinker.unlink(symlink: symlinkName)
        }
    }
}
