//  CleanerTests.swift

import Foundation
import Testing
@testable import LucaCore

struct CleanerTests {
    
    @Test
    func test_clean_installedTools() async throws {
        let fileManager = FileManagerWrapperMock()

        let installer = Installer(fileManager: fileManager)
        let fixture = Fixture(filename: "Lucafile_valid", type: "yml")
        let bundle = Bundle.module
        let path = try #require(bundle.path(forResource: fixture.filename, ofType: fixture.type))
        
        #expect(!fileManager.fileExists(atPath: fileManager.toolsFolder.path))
        #expect(!fileManager.fileExists(atPath: fileManager.activeFolder.path))
        
        try await installer.install(installationType: .spec(specPath: URL(string: path)!))

        #expect(fileManager.fileExists(atPath: fileManager.toolsFolder.path))
        #expect(fileManager.fileExists(atPath: fileManager.activeFolder.path))

        let uninstaller = Uninstaller(fileManager: fileManager)
        try uninstaller.uninstall(installedTools: true, localSymLinks: false)

        #expect(!fileManager.fileExists(atPath: fileManager.toolsFolder.path))
        #expect(fileManager.fileExists(atPath: fileManager.activeFolder.path))
    }
    
    @Test
    func test_clean_symLinks() async throws {
        let fileManager = FileManagerWrapperMock()

        let installer = Installer(fileManager: fileManager)
        let fixture = Fixture(filename: "Lucafile_valid", type: "yml")
        let bundle = Bundle.module
        let path = try #require(bundle.path(forResource: fixture.filename, ofType: fixture.type))
        
        #expect(!fileManager.fileExists(atPath: fileManager.toolsFolder.path))
        #expect(!fileManager.fileExists(atPath: fileManager.activeFolder.path))
        
        try await installer.install(installationType: .spec(specPath: URL(string: path)!))

        #expect(fileManager.fileExists(atPath: fileManager.toolsFolder.path))
        #expect(fileManager.fileExists(atPath: fileManager.activeFolder.path))

        let uninstaller = Uninstaller(fileManager: fileManager)
        try uninstaller.uninstall(installedTools: false, localSymLinks: true)
        
        #expect(fileManager.fileExists(atPath: fileManager.toolsFolder.path))
        #expect(!fileManager.fileExists(atPath: fileManager.activeFolder.path))
    }
}
