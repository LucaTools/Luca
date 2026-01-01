import Foundation

public final class InstalledToolsLister {
    
    private let fileManager: InstalledToolsFileManaging
    
    public init(fileManager: InstalledToolsFileManaging) {
        self.fileManager = fileManager
    }
    
    public func installedTools() throws -> [String: [String]] {
        let toolsFolder = fileManager.toolsFolder
        
        guard fileManager.fileExists(atPath: toolsFolder.path) else {
            return [:]
        }
        
        let toolURLs = try fileManager.contentsOfDirectory(at: toolsFolder, includingPropertiesForKeys: nil, options: .skipsHiddenFiles)
        
        var result: [String: [String]] = [:]
        
        for toolURL in toolURLs {
            let toolName = toolURL.lastPathComponent
            
            // Check if it is a directory
            if let attributes = try? fileManager.attributesOfItem(atPath: toolURL.path),
               let type = attributes[.type] as? FileAttributeType,
               type == .typeDirectory {
                
                let versionURLs = try fileManager.contentsOfDirectory(at: toolURL, includingPropertiesForKeys: nil, options: .skipsHiddenFiles)
                let versions = versionURLs.map { $0.lastPathComponent }.sorted()
                
                if !versions.isEmpty {
                    result[toolName] = versions
                }
            }
        }
        
        return result
    }
}
