//  RepoEntry.swift

import Foundation

/// A repository entry in the `repos:` dictionary of a Lucafile.
///
/// A `RepoEntry` can be decoded from two YAML forms:
///
/// - **Bare string** (URL only, version inherited from each skill):
///   ```yaml
///   repos:
///     vercel: vercel-labs/agent-skills
///   ```
/// - **Object** (URL with an optional default version for all skills in this repo):
///   ```yaml
///   repos:
///     vercel:
///       url: vercel-labs/agent-skills
///       version: v1.2.0
///   ```
struct RepoEntry: Decodable {
    /// The repository URL or `owner/repo` shorthand.
    let url: String
    /// An optional default git ref applied to all skills that reference this entry
    /// and do not specify their own `version:` field. May be `"latest"` to always resolve
    /// to the repository's current default-branch HEAD.
    let version: String?

    init(url: String, version: String? = nil) {
        self.url = url
        self.version = version
    }

    init(from decoder: Decoder) throws {
        if let bare = try? decoder.singleValueContainer().decode(String.self) {
            url = bare
            version = nil
        } else {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            url = try container.decode(String.self, forKey: .url)
            version = try container.decodeIfPresent(String.self, forKey: .version)
        }
    }

    private enum CodingKeys: String, CodingKey {
        case url, version
    }
}
