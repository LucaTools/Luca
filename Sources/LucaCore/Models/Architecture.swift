//  Architecture.swift

import Foundation

/// Represents CPU architectures for Mach-O and ELF binaries.
public enum Architecture: String, Codable, Equatable, Sendable {
    /// ARM64 as used in Mach-O binaries (macOS/Apple platforms).
    case arm64
    /// AArch64 as used in ELF binaries (Linux).
    case aarch64
    case x86_64
    case universal

    /// The architecture of the current host machine.
    public static var host: Architecture {
        #if arch(arm64) && os(Linux)
        return .aarch64
        #elseif arch(arm64)
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
            #if os(Linux)
            return false
            #else
            return true
            #endif
        case .arm64, .aarch64, .x86_64:
            return self == Architecture.host
        }
    }
}
