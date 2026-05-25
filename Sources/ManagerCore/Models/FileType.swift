//  FileType.swift

import Foundation

/// The detected type of a downloaded release asset.
enum FileType: String {
    /// A ZIP archive (`.zip`).
    case zip
    /// A gzip-compressed tar archive (`.tar.gz` / `.tgz`).
    case targz
    /// A standalone executable binary (Mach-O, ELF, or PE).
    case executable
}
