//  Unarchiving.swift

import Foundation

protocol Unarchiving {
    func unarchive(_ tool: Tool, filePath: URL) throws -> URL
}
