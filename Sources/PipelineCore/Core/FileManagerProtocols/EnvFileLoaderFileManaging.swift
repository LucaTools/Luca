//  EnvFileLoaderFileManaging.swift

import Foundation

/// File system interface for ``EnvFileLoader``.
public protocol EnvFileLoaderFileManaging {
    func contents(atPath path: String) -> Data?
}

extension FileManager: EnvFileLoaderFileManaging {}
