//  SpecLoader.swift

import Foundation
import Yams

struct SpecLoader: SpecLoading {
    
    enum ReleaseInfoProviderError: Error, LocalizedError, Equatable {
        case missingSpec(String)
        
        var errorDescription: String? {
            switch self {
            case .missingSpec(let path):
                return "Missing spec at path: \(path)"
            }
        }
    }
    
    private let fileManager: FileManager
    
    init(fileManager: FileManager) {
        self.fileManager = fileManager
    }
    
    func loadSpec(at path: URL) throws -> Spec {
        guard let data = fileManager.contents(atPath: path.path) else {
            throw ReleaseInfoProviderError.missingSpec(path.path)
        }
        return try YAMLDecoder().decode(Spec.self, from: data)
    }
}
