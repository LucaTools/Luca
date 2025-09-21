//  Release.swift

import Foundation

struct Release: Codable, Equatable {
    let organization: String
    let repository: String
    let version: String
}
