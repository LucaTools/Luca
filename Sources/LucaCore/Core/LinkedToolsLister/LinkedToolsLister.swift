import Foundation

public final class LinkedToolsLister {
    
    public struct LinkedTool {
        public let name: String
        public let version: String
        public let binaryName: String
        public let path: String
    }
    
    private let fileManager: FileManaging
    
    public init(fileManager: FileManaging) {
        self.fileManager = fileManager
    }
    
    public func linkedTools() throws -> [LinkedTool] {
        let activeFolder = fileManager.activeFolder
        
        guard fileManager.fileExists(atPath: activeFolder.path) else {
            return []
        }
        
        let activeToolURLs = try fileManager.contentsOfDirectory(at: activeFolder, includingPropertiesForKeys: nil, options: .skipsHiddenFiles)
        
        var linkedTools: [LinkedTool] = []
        let toolsFolderPath = fileManager.toolsFolder.path
        
        for toolURL in activeToolURLs {
            let binaryName = toolURL.lastPathComponent
            
            // Check if it is a symlink
            if let attributes = try? fileManager.attributesOfItem(atPath: toolURL.path),
               let type = attributes[.type] as? FileAttributeType,
               type == .typeSymbolicLink {
                
                let destinationPath = try fileManager.destinationOfSymbolicLink(atPath: toolURL.path)
                
                // Check if the destination is within the tools folder
                if destinationPath.hasPrefix(toolsFolderPath) {
                    let relativePath = String(destinationPath.dropFirst(toolsFolderPath.count))
                    let components = relativePath.split(separator: "/", maxSplits: 2, omittingEmptySubsequences: true)
                    
                    if components.count >= 2 {
                        let toolName = String(components[0])
                        let version = String(components[1])
                        
                        linkedTools.append(
                            LinkedTool(
                                name: toolName,
                                version: version,
                                binaryName: binaryName,
                                path: destinationPath
                            )
                        )
                    }
                }
            }
        }
        
        return linkedTools
    }
}
