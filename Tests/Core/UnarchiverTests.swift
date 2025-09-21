//  UnarchiverTests.swift

import Foundation
import Testing
@testable import LucaCore

struct UnarchiverTests {
    
    @Test
    func unarchive_zip() throws {
        let unarchiverFileManager = UnarchiverFileManagerMock(fileManager: .default)
        let sut = Unarchiver(fileManager: unarchiverFileManager)
        
        let tool = Tool(name: "Mock", version: "1.2.0", url: URL(string: "https://example.com")!, binaryPath: nil)
        
        let bundle = Bundle.module
        let fixture = Fixture(filename: "MockContent", type: "zip")
        let path = try #require(bundle.path(forResource: fixture.filename, ofType: fixture.type))
        
        let destination = try sut.unarchive(tool, filePath: URL(filePath: path))
        
        let fileManager = FileManager.default
        #expect(fileManager.fileExists(atPath: destination.path))
        #expect(fileManager.fileExists(atPath: destination.appending(component: "MockContent.txt").path))
    }
}
