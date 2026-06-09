//  ParamsFileLoaderFileManaging.swift

import Foundation

/// File system interface for ``ParamsFileLoader``.
public protocol ParamsFileLoaderFileManaging {
    func contents(atPath path: String) -> Data?
}

extension FileManager: ParamsFileLoaderFileManaging {}
