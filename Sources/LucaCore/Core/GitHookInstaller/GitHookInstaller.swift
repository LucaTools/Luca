//  GitHookInstaller.swift

import Foundation

public struct GitHookInstaller {
    
    private let fileManager: GitHookInstallerFileManaging
    private let printer: Printing
    
    public init(fileManager: GitHookInstallerFileManaging, printer: Printing) {
        self.fileManager = fileManager
        self.printer = printer
    }
    
    public func installPostCheckoutHook() throws {
        let currentDirectory = URL(fileURLWithPath: fileManager.currentDirectoryPath)
        let gitDirectory = currentDirectory.appending(component: ".git")
        
        // Skip if not a git repository
        guard fileManager.fileExists(atPath: gitDirectory.path) else {
            return
        }
        
        let sourceHookPath = fileManager.homeDirectoryForCurrentUser
            .appending(components: Constants.toolFolder, "post-checkout")
        
        // Warn and continue if source hook doesn't exist
        guard fileManager.fileExists(atPath: sourceHookPath.path) else {
            printer.printFormatted("\(.raw("⚠️ Post-checkout hook source not found at \(sourceHookPath.path)"))")
            return
        }
        
        let hooksDirectory = gitDirectory.appending(component: "hooks")
        let destinationHookPath = hooksDirectory.appending(component: "post-checkout")
        
        // Skip if hook already exists (preserve existing hook)
        guard !fileManager.fileExists(atPath: destinationHookPath.path) else {
            return
        }
        
        // Copy hook file
        try fileManager.copyItem(at: sourceHookPath, to: destinationHookPath)
        
        // Set executable permissions (0o755)
        try fileManager.setAttributes([.posixPermissions: 0o755], ofItemAtPath: destinationHookPath.path)
        
        printer.printFormatted("\(.info("🪝 Installed post-checkout hook"))")
    }
}
