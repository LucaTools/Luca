//  Arguments.swift

import Foundation
import LucaCore

struct Arguments: Equatable {
    
    let spec: String?
    let identifier: String?
    let asset: String?
    let name: String?
    let version: String?
    let url: URL?
    let binaryPath: String?
    let checksum: String?
    let algorithm: ChecksumAlgorithm?
    
    init(
        spec: String? = nil,
        identifier: String? = nil,
        asset: String? = nil,
        name: String? = nil,
        version: String? = nil,
        url: URL? = nil,
        binaryPath: String?,
        checksum: String? = nil,
        algorithm: ChecksumAlgorithm? = nil
    ) {
        self.spec = spec
        self.identifier = identifier
        self.asset = asset
        self.name = name
        self.version = version
        self.url = url
        self.binaryPath = binaryPath
        self.checksum = checksum
        self.algorithm = algorithm
    }
}

extension Arguments: CustomStringConvertible {
    
    var description: String {
        """
         spec: \(spec ?? "nil")
         identifier: \(identifier ?? "nil")
         asset: \(asset ?? "nil")
         name: \(name ?? "nil")
         version: \(version ?? "nil")
         url: \(url?.absoluteString ?? "nil")
         binaryPath: \(binaryPath ?? "nil")
         checksum: \(checksum ?? "nil")
         algorithm: \(algorithm?.rawValue ?? "nil")
        """
    }
}
