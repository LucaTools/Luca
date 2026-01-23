//  SymLinking.swift

import Foundation

protocol SymLinking {
    func setSymLink(for tool: Tool) throws -> URL
}
