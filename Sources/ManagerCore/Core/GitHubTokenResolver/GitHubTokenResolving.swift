//  GitHubTokenResolving.swift

import Foundation

/// Resolves a GitHub authentication token for a given host.
protocol GitHubTokenResolving {
    /// Returns the token configured for `host`, or `nil` if none is set.
    /// - Parameter host: The hostname of the GitHub instance (e.g. `"github.com"` or a
    ///   GitHub Enterprise Server hostname such as `"ghe.my-company.com"`).
    func token(forHost host: String) -> String?
}
