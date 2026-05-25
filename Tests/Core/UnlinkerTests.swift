import Foundation
import Testing
@testable import LucaCore
@testable import ManagerCore

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

    @Test
    func unlink_danglingSymlink_removesSymlink() throws {
        let fileManager = FileManagerWrapperMock()
        let unlinker = Unlinker(fileManager: fileManager, printer: PrinterMock())

        let symlinkName = "mytool"
        let symlinkFile = fileManager.symlinksFolder.appending(component: symlinkName)
        let nonExistentTarget = fileManager.toolsFolder
            .appending(component: "mytool")
            .appending(component: "1.0.0")
            .appending(component: "mytool")

        // Create a symlink pointing to a non-existent target (dangling symlink)
        try fileManager.createDirectory(at: fileManager.symlinksFolder, withIntermediateDirectories: true)
        try fileManager.createSymbolicLink(at: symlinkFile, withDestinationURL: nonExistentTarget)

        // The symlink file itself exists, but fileExists (which follows symlinks) returns false
        #expect((try? fileManager.attributesOfItem(atPath: symlinkFile.path)) != nil)
        #expect(!fileManager.fileExists(atPath: symlinkFile.path))

        try unlinker.unlink(symlink: symlinkName)

        #expect((try? fileManager.attributesOfItem(atPath: symlinkFile.path)) == nil)
    }
}
