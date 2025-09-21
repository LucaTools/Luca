//  SymLinkerTests.swift

import Foundation
import Testing
@testable import LucaCore

struct SymLinkerTests {
    
    private let fileManager: FileManager = .default
    
    @Test
    func createSymLink_toolExists() throws {
        let tool = EnrichedTool(name: "ToggleGen", version: "1.0.0", url: URL(string: "https://example.com")!, binaryPath: "ToggleGen")
        
        let symLinkFileManager = SymLinkFileManagerMock(fileManager: fileManager)
        
        let toolFilePath = symLinkFileManager.toolsFolder
            .appending(components: tool.name, "1.0.0")
            .appending(components: tool.binaryPath)
        try fileManager.createDirectory(at: toolFilePath.deletingLastPathComponent(), withIntermediateDirectories: true)
        fileManager.createFile(atPath: toolFilePath.path, contents: Data())
        
        let sut = SymLinker(fileManager: symLinkFileManager)
        
        let symLinkPath = symLinkFileManager.activeFolder
            .appending(component: tool.binaryName)
            .path
        
        #expect(!symLinkExists(atPath: symLinkPath))
        
        try sut.setSymLink(for: tool)
        
        #expect(symLinkExists(atPath: symLinkPath))
    }
    
    @Test
    func createSymLink_toolExists_binaryPathSpecified() throws {
        let tool = EnrichedTool(name: "ToggleGen", version: "1.0.0", url: URL(string: "https://example.com")!, binaryPath: "ToggleGen")
        
        let symLinkFileManager = SymLinkFileManagerMock(fileManager: fileManager)
        
        let toolFilePath = symLinkFileManager.toolsFolder
            .appending(components: tool.name, "1.0.0")
            .appending(components: tool.binaryPath)
        try fileManager.createDirectory(at: toolFilePath.deletingLastPathComponent(), withIntermediateDirectories: true)
        fileManager.createFile(atPath: toolFilePath.path, contents: Data())
        
        let sut = SymLinker(fileManager: symLinkFileManager)
        
        let symLinkPath = symLinkFileManager.activeFolder
            .appending(component: tool.binaryName)
            .path
        
        #expect(!symLinkExists(atPath: symLinkPath))
        
        try sut.setSymLink(for: tool)
        
        #expect(symLinkExists(atPath: symLinkPath))
    }
    
    @Test
    func createSymLink_toolExists_nestedBinaryPathSpecified() throws {
        let tool = EnrichedTool(name: "ToggleGen", version: "1.0.0", url: URL(string: "https://example.com")!, binaryPath: "bin/ToggleGen")
        
        let symLinkFileManager = SymLinkFileManagerMock(fileManager: fileManager)
        
        let toolFilePath = symLinkFileManager.toolsFolder
            .appending(components: tool.name, "1.0.0")
            .appending(components: tool.binaryPath)
        try fileManager.createDirectory(at: toolFilePath.deletingLastPathComponent(), withIntermediateDirectories: true)
        fileManager.createFile(atPath: toolFilePath.path, contents: Data())
        
        let sut = SymLinker(fileManager: symLinkFileManager)
        
        let symLinkPath = symLinkFileManager.activeFolder
            .appending(component: tool.binaryName)
            .path
        
        #expect(!symLinkExists(atPath: symLinkPath))
        
        try sut.setSymLink(for: tool)
        
        #expect(symLinkExists(atPath: symLinkPath))
    }
    
    @Test
    func createSymLink_symLinkExists() throws {
        let tool = EnrichedTool(name: "ToggleGen", version: "1.0.0", url: URL(string: "https://example.com")!, binaryPath: "ToggleGen")
        
        let symLinkFileManager = SymLinkFileManagerMock(fileManager: fileManager)
        
        let toolFolderPath = symLinkFileManager.toolsFolder
            .appending(components: tool.name, "1.0.0")
        try fileManager.createDirectory(at: toolFolderPath, withIntermediateDirectories: true)
        let toolFilePath = toolFolderPath
            .appending(components: tool.binaryPath)
        fileManager.createFile(atPath: toolFilePath.path, contents: Data())
        
        let sut = SymLinker(fileManager: symLinkFileManager)
        
        let symLinkPath = symLinkFileManager.activeFolder
            .appending(component: tool.binaryName)
            .path
        
        try sut.setSymLink(for: tool)
        try sut.setSymLink(for: tool)

        #expect(symLinkExists(atPath: symLinkPath))
    }
    
    @Test
    func createSymLink_toolDoesNotExist() throws {
        let tool = EnrichedTool(name: "ToggleGen", version: "1.0.0", url: URL(string: "https://example.com")!, binaryPath: "bin/ToggleGen")
        
        let symLinkFileManager = SymLinkFileManagerMock(fileManager: fileManager)
        
        let sut = SymLinker(fileManager: symLinkFileManager)
        
        let symLinkPath = symLinkFileManager.activeFolder
            .appending(component: tool.binaryName)
            .path
        
        #expect(!symLinkExists(atPath: symLinkPath))
        
        let expectedDestination = symLinkFileManager.toolsFolder
            .appending(components: tool.name, tool.version)
            .appending(components: tool.binaryPath)

        #expect(throws: SymLinker.SymLinkerError.missingBinaryFile(binaryName: tool.binaryName, expectedLocation: expectedDestination.path)) {
            try sut.setSymLink(for: tool)
        }
    }
    
    // MARK: - Private
    
    private func symLinkExists(atPath path: String) -> Bool {
        do {
            let attributes = try fileManager.attributesOfItem(atPath: path)
            if let fileType = attributes[.type] as? FileAttributeType {
                return fileType == .typeSymbolicLink
            }
            return false
        } catch {
            return false
        }
    }
}
