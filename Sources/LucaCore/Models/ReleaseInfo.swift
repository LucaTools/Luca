//  ReleaseInfo.swift

import Foundation

struct ReleaseInfo: Decodable {
    let assets: [ReleaseAsset]
}

struct ReleaseAsset: Decodable, Equatable {
    let name: String
    let url: String

    enum CodingKeys: String, CodingKey {
        case name
        case url = "browser_download_url"
    }
}

