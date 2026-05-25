//  ArchitectureValidatorFileManagerMock.swift

import Foundation
@testable import LucaFoundation
@testable import ManagerCore

struct ArchitectureValidatorFileManagerMock: ArchitectureValidatorFileManaging {
    
    private(set) var fileManager: FileManager
    
    init(fileManager: FileManager = .default) {
        self.fileManager = fileManager
    }
    
    func contents(atPath path: String) -> Data? {
        fileManager.contents(atPath: path)
    }
    
    func fileExists(atPath path: String) -> Bool {
        fileManager.fileExists(atPath: path)
    }
}
