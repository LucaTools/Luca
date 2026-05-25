//  Downloader.swift

import Foundation

/// Downloads release archives and executables from remote URLs.
///
/// The `Downloader` handles fetching tool releases from remote servers,
/// supporting archive formats (zip, tar.gz) and standalone executables.
///
/// ## Topics
///
/// ### Downloading Files
/// - ``downloadRelease(at:)``
struct Downloader: Downloading {

    private var fileDownloader: FileDownloading

    init(fileDownloader: FileDownloading) {
        self.fileDownloader = fileDownloader
    }

    /// Downloads a release from the specified URL.
    ///
    /// - Parameter url: The URL to download from.
    /// - Returns: A URL to the downloaded file in a temporary location.
    func downloadRelease(at url: URL) async throws -> URL {
        let (tempDownloadURL, _) = try await fileDownloader.download(from: url)
        return tempDownloadURL
    }
}
