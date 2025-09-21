//  SpecLoader.swift

import Foundation
import Yams

struct SpecLoader: SpecLoading {
    
    enum SpecLoaderError: Error, LocalizedError {
        case missingSpec(String)
        case invalidSpec(String, Error)
        
        var errorDescription: String? {
            switch self {
            case .missingSpec(let path):
                return "Missing spec at path: \(path)"
            case .invalidSpec(let path, let error):
                return "Invalid spec at path: \(path). \(error)"
            }
        }
    }
    
    private let fileManager: FileManager
    
    init(fileManager: FileManager) {
        self.fileManager = fileManager
    }
    
    func loadSpec(at path: URL) throws -> Spec {
        guard let data = fileManager.contents(atPath: path.path) else {
            throw SpecLoaderError.missingSpec(path.path)
        }
        do {
            return try YAMLDecoder().decode(Spec.self, from: data)
        } catch {
            let nsError = NSError(
                domain: "io.github.luca.specLoader",
                code: 1,
                userInfo: [NSUnderlyingErrorKey: error]
            )
            throw SpecLoaderError.invalidSpec(path.path, nsError)
        }
    }
}
