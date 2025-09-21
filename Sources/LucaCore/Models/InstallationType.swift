//  InstallationType.swift

import Foundation

public enum InstallationType {
    case spec(specPath: URL)
    case individual(identifier: String, asset: String?, binaryPath: String?)
    case individualInline(name: String, version: String, url: URL, binaryPath: String?)
}
