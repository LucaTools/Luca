import Foundation

public struct VersionLister {
    
    public enum VersionListerError: Error, LocalizedError, Equatable {
        case toolNotFound(tool: String)
        
        public var errorDescription: String? {
            switch self {
            case .toolNotFound(let tool):
                return "Tool '\(tool)' not found."
            }
        }
    }

    private let fileManager: FileManaging
    
    public init(fileManager: FileManaging) {
        self.fileManager = fileManager
    }

    public func versions(for tool: String) throws -> [String] {
        let toolFolder = fileManager.toolsFolder.appending(component: tool)
        guard fileManager.fileExists(atPath: toolFolder.path) else {
            throw VersionListerError.toolNotFound(tool: tool)
        }
        
        let contents = try fileManager.contentsOfDirectory(at: toolFolder, includingPropertiesForKeys: nil, options: .skipsHiddenFiles)
        return contents.map { $0.lastPathComponent }
    }
}
