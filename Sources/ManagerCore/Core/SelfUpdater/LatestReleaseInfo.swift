//  LatestReleaseInfo.swift

import Foundation

/// Minimal response model for the GitHub `/releases/latest` endpoint.
struct LatestReleaseInfo: Decodable {

    /// The release tag name as set on GitHub (e.g. `"1.2.3"` or `"v1.2.3"`).
    let tagName: String

    private enum CodingKeys: String, CodingKey {
        case tagName = "tag_name"
    }
}
