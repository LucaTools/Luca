//  FileTypeDetectorFileManagerMock.swift

import Foundation
@testable import LucaFoundation
@testable import ManagerCore

class FileTypeDetectorFileManagerMock: FileTypeDetectorFileManaging {
    
    private(set) var fileManager: FileManager
    
    init(fileManager: FileManager = .default) {
        self.fileManager = fileManager
    }
    
    public func attributesOfItem(atPath path: String) throws -> [FileAttributeKey: Any] {
        try fileManager.attributesOfItem(atPath: path)
    }
}
