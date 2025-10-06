//  ChecksumValidatorFileManaging.swift

import Foundation

public protocol ChecksumValidatorFileManaging {
    func contents(atPath path: String) -> Data?
    func fileExists(atPath: String) -> Bool
}
