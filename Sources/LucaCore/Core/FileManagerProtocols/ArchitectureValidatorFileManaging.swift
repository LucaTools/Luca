//  ArchitectureValidatorFileManaging.swift

import Foundation

public protocol ArchitectureValidatorFileManaging {
    func contents(atPath path: String) -> Data?
    func fileExists(atPath: String) -> Bool
}
