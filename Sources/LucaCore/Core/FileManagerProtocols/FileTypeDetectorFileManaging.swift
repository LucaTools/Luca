//  FileTypeDetectorFileManaging.swift

import Foundation

public protocol FileTypeDetectorFileManaging {
    func attributesOfItem(atPath path: String) throws -> [FileAttributeKey: Any]
}
