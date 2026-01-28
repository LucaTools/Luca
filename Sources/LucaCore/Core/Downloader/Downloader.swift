//  Downloader.swift

import Foundation

/// Downloads release archives and executables from remote URLs.
///
/// The `Downloader` handles fetching tool releases from remote servers,
/// supporting both archive formats (ZIP, tar.gz) and standalone executables.
///
/// ## Supported File Types
///
/// - `.zip` - ZIP archives
/// - `.tar.gz` - Gzipped tar archives
/// - No extension - Treated as executable files
///
/// ## Topics
///
/// ### Downloading Files
/// - ``downloadRelease(at:)``
struct Downloader: Downloading {
    
    enum DownloaderError: Error, LocalizedError, Equatable {
        case unsupportedFileType(URL)
        
        var errorDescription: String? {
            switch self {
            case .unsupportedFileType(let url):
                return "File at \(url.absoluteString) has unsupported file type. Supported file types are: \(SupportedFileTypes.allCases.map { $0.rawValue })."
            }
        }
    }
    
    enum SupportedFileTypes: String, CaseIterable {
        case zip = "zip"
        case targz = "tar.gz"
    }
    
    private var fileDownloader: FileDownloading
    
    init(fileDownloader: FileDownloading) {
        self.fileDownloader = fileDownloader
    }
    
    /// Downloads a release from the specified URL.
    ///
    /// - Parameter url: The URL to download from.
    /// - Returns: A URL to the downloaded file in a temporary location.
    /// - Throws: ``DownloaderError/unsupportedFileType(_:)`` if the URL has
    ///   an unsupported file extension.
    func downloadRelease(at url: URL) async throws -> URL {
        if SupportedFileTypes.allCases.contains(where: {
            url.lastPathComponent.hasSuffix($0.rawValue)
        }) == false {
            if url.pathExtension != "" {
                throw DownloaderError.unsupportedFileType(url)
            }
        }
        
        let (tempDownloadURL, _) = try await fileDownloader.download(from: url)
        return tempDownloadURL
    }
}
