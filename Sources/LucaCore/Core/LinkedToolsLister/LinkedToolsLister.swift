//  LinkedToolsLister.swift

import Foundation

/// Lists tools that are currently symlinked into the project's `.luca/tools/` directory.
public struct LinkedToolsLister {

    /// A tool that is currently symlinked into the tools folder.
    public struct LinkedTool {
        /// The tool's logical name.
        public let name: String
        /// The installed version of the tool.
        public let version: String
        /// The name of the symlink binary in the tools folder.
        public let binaryName: String
        /// The resolved destination path of the symlink.
        public let path: String
    }

    private let fileManager: FileManaging

    public init(fileManager: FileManaging) {
        self.fileManager = fileManager
    }

    /// Returns all tools currently symlinked in the project's tools folder.
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
