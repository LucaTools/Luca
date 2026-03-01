//  ReleaseInfo.swift

import Foundation

/// GitHub API response containing the list of downloadable assets for a release.
struct ReleaseInfo: Decodable {
    /// The assets available for this release.
    let assets: [ReleaseAsset]
}

/// A single downloadable asset attached to a GitHub release.
struct ReleaseAsset: Decodable, Equatable {
    /// The filename of the asset.
    let name: String
    /// The direct browser download URL for the asset.
    let url: String

    enum CodingKeys: String, CodingKey {
        case name
        case url = "browser_download_url"
    }
}

