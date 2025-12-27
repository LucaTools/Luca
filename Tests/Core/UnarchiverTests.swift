//  UnarchiverTests.swift

import Foundation
import Testing
@testable import LucaCore

struct UnarchiverTests {
    
    @Test
    func unarchive_zip() throws {
        let unarchiverFileManager = UnarchiverFileManagerMock(fileManager: .default)
        let sut = Unarchiver(fileManager: unarchiverFileManager)
        
        let installationDestination = unarchiverFileManager.toolsFolder
            .appending(components: "Mock", "1.2.0")

        try unarchiverFileManager.createDirectory(at: installationDestination, withIntermediateDirectories: true)
        
        let bundle = Bundle.module
        let fixture = Fixture(filename: "MockContent", type: "zip")
        let path = try #require(bundle.path(forResource: fixture.filename, ofType: fixture.type))
        
        try sut.unarchive(filePath: URL(filePath: path), installationDestination: installationDestination)
        
        let fileManager = FileManager.default
        #expect(fileManager.fileExists(atPath: installationDestination.path))
        #expect(fileManager.fileExists(atPath: installationDestination.appending(component: "MockContent.txt").path))
    }
}
