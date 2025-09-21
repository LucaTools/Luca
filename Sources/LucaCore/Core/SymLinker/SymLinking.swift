//  SymLinking.swift

import Foundation

protocol SymLinking {
    func setSymLink(for tool: EnrichedTool) throws -> URL
}
