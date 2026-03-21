//  Installer.swift

import Foundation
import Noora

/// Orchestrates tool and skill installation for a project.
///
/// The `Installer` coordinates the complete installation process:
/// 1. Loads the tool or skill spec (Lucafile or inline parameters)
/// 2. Unlinks orphaned tools no longer present in the spec
/// 3. Delegates per-tool download, installation, and reinstallation to ``ToolInstalling``
/// 4. Delegates skill installation to ``SkillInstalling``
///
/// ## Usage
///
/// ```swift
/// let installer = Installer(
///     fileManager: FileManager.default,
///     ignoreArchitectureCheck: false,
///     printer: Printer()
/// )
/// try await installer.install(installationType: .spec(path: lucafilePath))
/// ```
///
/// ## Topics
///
/// ### Installing Tools
/// - ``install(installationType:)``
///
/// ### Installation Types
/// - ``InstallationType``
public struct Installer {

    private let fileManager: FileManaging
    private let printer: Printing
    private let linkedToolsLister: LinkedToolsLister
    private let unlinker: Unlinker
    private let ignoreArchitectureCheck: Bool
    private let quiet: Bool
    private let noora: Noorable
    private let toolInstaller: ToolInstalling
    private let skillInstaller: SkillInstalling
    private let specLoader: SpecLoading

    public init(
        fileManager: FileManaging,
        ignoreArchitectureCheck: Bool,
        quiet: Bool = false,
        printer: Printing,
        noora: Noorable = Noora()
    ) {
        self.init(
            fileManager: fileManager,
            ignoreArchitectureCheck: ignoreArchitectureCheck,
            quiet: quiet,
            printer: printer,
            noora: noora,
            toolInstaller: nil,
            skillInstaller: nil,
            specLoader: nil
        )
    }

    init(
        fileManager: FileManaging,
        ignoreArchitectureCheck: Bool,
        quiet: Bool = false,
        printer: Printing,
        noora: Noorable = Noora(),
        toolInstaller: ToolInstalling? = nil,
        skillInstaller: SkillInstalling? = nil,
        specLoader: SpecLoading? = nil
    ) {
        self.fileManager = fileManager
        self.printer = printer
        self.linkedToolsLister = LinkedToolsLister(fileManager: fileManager)
        self.unlinker = Unlinker(fileManager: fileManager, printer: printer)
        self.ignoreArchitectureCheck = ignoreArchitectureCheck
        self.quiet = quiet
        self.noora = noora
        self.toolInstaller = toolInstaller ?? ToolInstaller(
            fileManager: fileManager,
            ignoreArchitectureCheck: ignoreArchitectureCheck,
            printer: printer
        )
        self.skillInstaller = skillInstaller ?? SkillInstaller()
        self.specLoader = specLoader ?? SpecLoader(fileManager: .default)
    }

    /// Installs tools based on the specified installation type.
    ///
    /// - Parameter installationType: Specifies how to determine which tools to install.
    ///   Can be either `.spec` to read from a Lucafile, or `.individual`/`.individualInline`
    ///   to install directly from a GitHub release.
    /// - Throws: An error if downloading, extracting, or linking fails.
    public func install(installationType: ToolInstallationType) async throws {
        if quiet {
            try await installQuietly(installationType: installationType)
        } else {
            try await installVerbose(installationType: installationType)
        }
    }
    
    /// Installs skills based on the specified installation type.
    ///
    /// - Parameter installationType: Specifies how to determine which skills to install.
    ///   Can be `.spec` to read from a Lucafile.
    /// - Throws: An error if downloading, extracting, or linking fails.
    public func install(installationType: SkillInstallationType) async throws {
        if quiet {
            try await installQuietly(installationType: installationType)
        } else {
            try await installVerbose(installationType: installationType)
        }
    }
    
    // MARK: - Private
    
    private func installQuietly(installationType: ToolInstallationType) async throws {
        try await noora.progressStep(
            message: "Installing tools",
            successMessage: "Tools have been installed for the current project",
            errorMessage: "Failed to install tools",
            showSpinner: true
        ) { updateMessage in
            let dataDownloader = DataDownloader(session: .shared)
            let releaseInfoProvider = ReleaseInfoProvider(dataDownloader: dataDownloader)
            let toolFactory = ToolFactory(releaseInfoProvider: releaseInfoProvider, specLoader: specLoader)
            
            updateMessage("Detecting tools to install")
            let tools = try await toolFactory.toolsForInstallationType(installationType)
            
            // Unlink orphaned tools only when installing from a spec
            if case .spec = installationType {
                try unlinkOrphanedTools(specTools: tools)
            }
            
            for tool in tools {
                updateMessage("Installing \(tool.name) \(tool.version)")
                if isToolInstalled(tool) {
                    try toolInstaller.reinstall(tool: tool)
                } else {
                    try await toolInstaller.install(tool: tool)
                }
            }
        }
    }

    private func installVerbose(installationType: ToolInstallationType) async throws {
        let dataDownloader = DataDownloader(session: .shared)
        let releaseInfoProvider = ReleaseInfoProvider(dataDownloader: dataDownloader)
        let toolFactory = ToolFactory(releaseInfoProvider: releaseInfoProvider, specLoader: specLoader)
        
        printer.printFormatted("\(.info("🧠 Detecting tools to install..."))")
        
        let tools = try await toolFactory.toolsForInstallationType(installationType)
        
        // Unlink orphaned tools only when installing from a spec
        if case .spec = installationType {
            try unlinkOrphanedTools(specTools: tools)
        }
        
        if !tools.isEmpty {
            printer.printFormatted("\(.info("🏃‍♂️ Installing tools for the current project."))")
            printer.printFormatted("")
            
            for tool in tools {
                if isToolInstalled(tool) {
                    try toolInstaller.reinstall(tool: tool)
                } else {
                    try await toolInstaller.install(tool: tool)
                }
                printer.printFormatted("")
            }
            printer.printFormatted("\(.success("🚀 Tools have been installed for the current project."))")
        } else {
            printer.printFormatted("\(.muted("🫥 No tools have been installed for the current project."))")
        }
    }
    
    private func installQuietly(installationType: SkillInstallationType) async throws {
        let skillsInfoFactory = SkillsInfoFactory(specLoader: specLoader)
        let skillsInfo = try await skillsInfoFactory.skillsInfoForInstallationType(installationType)
        for skillSet in skillsInfo.skillSets {
            try await install(skillSet, agents: skillsInfo.agents)
        }
    }
    
    private func installVerbose(installationType: SkillInstallationType) async throws {
        let skillsInfoFactory = SkillsInfoFactory(specLoader: specLoader)
        
        printer.printFormatted("\(.info("🧠 Detecting skills to install..."))")
        
        let skillsInfo = try await skillsInfoFactory.skillsInfoForInstallationType(installationType)
        if !skillsInfo.skillSets.isEmpty {
            printer.printFormatted("\(.info("🧠 Installing skills for the current project."))")
            printer.printFormatted("")
            for skillSet in skillsInfo.skillSets {
                try await install(skillSet, agents: skillsInfo.agents)
                printer.printFormatted("")
            }
            printer.printFormatted("\(.success("🚀 Skills have been installed for the current project."))")
        } else {
            printer.printFormatted("\(.muted("🫥 No skills have been installed for the current project."))")
        }
    }

    private func install(_ skillSet: SkillSet, agents: [String]?) async throws {
        printer.printFormatted("\(.raw("🧩 Installing skills from \(skillSet.repository)..."))")
        try await skillInstaller.install(skillSet: skillSet, agents: agents)
        printer.printFormatted("\(.primary("🙌 Skills from \(skillSet.repository) installed for the current project."))")
    }

    private func isToolInstalled(_ tool: Tool) -> Bool {
        let expectedBinaryLocation: URL = {
            let versionFolder = fileManager.toolsFolder
                .appending(components: tool.name, tool.version)
            if let binaryPath = tool.binaryPath {
                return versionFolder
                    .appending(components: binaryPath)
            }
            if let desiredBinaryName = tool.desiredBinaryName {
                return versionFolder
                    .appending(component: desiredBinaryName)
            }
            return versionFolder
        }()
        return fileManager.fileExists(atPath: expectedBinaryLocation.path)
    }

    private func unlinkOrphanedTools(specTools: [Tool]) throws {
        let linkedTools = try linkedToolsLister.linkedTools()
        
        // Build a set of tool names from spec for efficient lookup
        let specToolNames: Set<String> = Set(specTools.map(\.name))
        
        // Find linked tools that are not in the spec
        let orphanedTools = linkedTools.filter { linkedTool in
            !specToolNames.contains(linkedTool.name)
        }
        
        // Unlink each orphaned tool
        for orphanedTool in orphanedTools {
            printer.printFormatted("\(.raw("🧹 Unlinking \(orphanedTool.binaryName) (removed from spec)..."))")
            try unlinker.unlink(symlink: orphanedTool.binaryName)
        }
    }
}
