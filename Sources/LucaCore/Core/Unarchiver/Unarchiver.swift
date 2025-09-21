//  Unarchiver.swift

import Foundation

struct Unarchiver: Unarchiving {
    
    enum UnarchiverError: Error, LocalizedError {
        case failedToUnarchive(Error)
        
        var errorDescription: String? {
            switch self {
            case .failedToUnarchive(let error):
                return "Failed to unarchive with error '\(error)'."
            }
        }
    }
    
    private let fileManager: UnarchiverFileManaging
    
    init(fileManager: UnarchiverFileManaging) {
        self.fileManager = fileManager
    }
    
    func unarchive(_ tool: Tool, filePath: URL) throws -> URL {
        let destinationFolder = fileManager.toolsFolder
            .appending(components: tool.name, tool.version)

        try fileManager.createDirectory(at: destinationFolder, withIntermediateDirectories: true)

        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/env")
        process.arguments = ["unzip", "-q", "-o", filePath.path, "-d", destinationFolder.path]

        let stdoutPipe = Pipe()
        let stderrPipe = Pipe()
        process.standardOutput = stdoutPipe
        process.standardError = stderrPipe

        try process.run()
        process.waitUntilExit()

        if process.terminationStatus != 0 {
            let errData = stderrPipe.fileHandleForReading.readDataToEndOfFile()
            let errStr = String(data: errData, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? "Unknown error"
            let error = NSError(
                domain: "io.github.luca.unarchiver",
                code: Int(process.terminationStatus),
                userInfo: [NSLocalizedDescriptionKey: "Failed to unzip archive: \(errStr)"]
            )
            throw UnarchiverError.failedToUnarchive(error)
        }
        return destinationFolder
    }
}
