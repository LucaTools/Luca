//  Architecture.swift

import Foundation

/// Represents CPU architectures for Mach-O binaries.
public enum Architecture: String, Codable, Equatable, Sendable {
    case arm64
    case x86_64
    case universal
    
    /// The architecture of the current host machine.
    public static var host: Architecture {
        #if arch(arm64)
        return .arm64
        #elseif arch(x86_64)
        return .x86_64
        #else
        fatalError("Unsupported architecture")
        #endif
    }
    
    /// Returns `true` if this architecture is compatible with the host machine.
    /// Universal binaries are always compatible.
    public var isCompatibleWithHost: Bool {
        switch self {
        case .universal:
            return true
        case .arm64, .x86_64:
            return self == Architecture.host
        }
    }
}
