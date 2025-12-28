//  FileType.swift

import Foundation

enum FileType {
    case zip
    case executable
    case unknown(fileExtension: String)
}
