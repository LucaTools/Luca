//  GitHubTokenResolver.swift

import Foundation

/// Reads a per-host GitHub personal access token from environment variables.
///
/// `github.com` reads `LUCA_GITHUB_TOKEN`. Any other host — a GitHub Enterprise Server
/// instance — reads `LUCA_GITHUB_TOKEN_<HOST>`, where `<HOST>` is the hostname uppercased
/// with every non-alphanumeric character replaced by `_` (e.g. `ghe.my-company.com` becomes
/// `LUCA_GITHUB_TOKEN_GHE_MY_COMPANY_COM`).
struct GitHubTokenResolver: GitHubTokenResolving {

    private let environment: [String: String]

    init(environment: [String: String] = ProcessInfo.processInfo.environment) {
        self.environment = environment
    }

    // MARK: - GitHubTokenResolving

    func token(forHost host: String) -> String? {
        let variableName = host == "github.com"
            ? "LUCA_GITHUB_TOKEN"
            : "LUCA_GITHUB_TOKEN_\(Self.sanitize(host))"
        let value = environment[variableName]
        return (value?.isEmpty ?? true) ? nil : value
    }

    // MARK: - Private

    private static func sanitize(_ host: String) -> String {
        String(host.uppercased().map { $0.isLetter || $0.isNumber ? $0 : "_" })
    }
}
