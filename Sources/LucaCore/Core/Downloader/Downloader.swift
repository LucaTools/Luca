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
        case zip = "zip"
        case targz = "tar.gz"
    }
    
    private var fileDownloader: FileDownloading
    
    init(fileDownloader: FileDownloading) {
        self.fileDownloader = fileDownloader
    }
    
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
