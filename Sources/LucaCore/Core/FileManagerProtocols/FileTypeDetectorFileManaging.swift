//  FileTypeDetectorFileManaging.swift

import Foundation

/// File system interface for ``FileTypeDetector``.
public protocol FileTypeDetectorFileManaging {
    func attributesOfItem(atPath path: String) throws -> [FileAttributeKey: Any]
}
