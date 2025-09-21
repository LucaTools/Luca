//  Downloader.swift

import Foundation

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
        case zip
    }
    
    private var fileDownloader: FileDownloading
    
    init(fileDownloader: FileDownloading) {
        self.fileDownloader = fileDownloader
    }
    
    func downloadArchive(at url: URL) async throws -> URL {
        guard SupportedFileTypes(rawValue: url.pathExtension) != nil else {
            throw DownloaderError.unsupportedFileType(url)
        }
        let (tempDownloadURL, _) = try await fileDownloader.download(from: url)
        return tempDownloadURL
    }
}
