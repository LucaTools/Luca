//  Downloader.swift

import Foundation

/// Downloads release archives and executables from remote URLs.
///
/// The `Downloader` handles fetching tool releases from remote servers,
/// supporting archive formats (zip, tar.gz) and standalone executables.
/// When the target host is a GitHub Enterprise Server instance (any host other than
/// `github.com`) and a token is configured for it, the request carries an
/// `Authorization: Bearer` header so private-repository release assets can be downloaded.
/// `github.com` never receives this header: its release-asset downloads redirect to a
/// separate presigned-URL storage host, and forwarding a token there would leak it.
///
/// ## Topics
///
/// ### Downloading Files
/// - ``downloadRelease(at:)``
struct Downloader: Downloading {

    private var fileDownloader: FileDownloading
    private var tokenResolver: GitHubTokenResolving

    init(fileDownloader: FileDownloading, tokenResolver: GitHubTokenResolving = GitHubTokenResolver()) {
        self.fileDownloader = fileDownloader
        self.tokenResolver = tokenResolver
    }

    /// Downloads a release from the specified URL.
    ///
    /// - Parameter url: The URL to download from.
    /// - Returns: A URL to the downloaded file in a temporary location.
    func downloadRelease(at url: URL) async throws -> URL {
        var request = URLRequest(url: url)
        // Requesting the raw asset bytes explicitly is required by GitHub's release-asset API
        // endpoint (".../releases/assets/{id}"), which otherwise returns JSON metadata. Harmless
        // for plain download URLs, which ignore Accept and return the file regardless.
        request.setValue("application/octet-stream", forHTTPHeaderField: "Accept")
        if let host = url.host, host != "github.com", let token = tokenResolver.token(forHost: host) {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        let (tempDownloadURL, _) = try await fileDownloader.download(for: request)
        return tempDownloadURL
    }
}
