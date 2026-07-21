//  Installer.swift

import Foundation
import LucaFoundation
import Noora

/// Orchestrates tool and skill installation for a project.
///
/// The `Installer` coordinates the complete installation process:
/// 1. Loads the tool or skill spec (Lucafile or inline parameters)
/// 2. Unlinks orphaned tools no longer present in the spec
/// 3. Delegates per-tool download, installation, and reinstallation to ``ToolInstalling``
/// 4. Delegates skill installation via the native pipeline (``SkillDownloading`` + ``SkillSymLinking``)
///    or the npx-based ``SkillInstalling`` path, depending on the `useNpx` flag
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
/// ### Installing Skills
/// - ``install(installationType:useNpx:)``
public struct Installer {

    enum InstallerError: Error, LocalizedError, Equatable {
        case runningFromHomeDirectory
        case unsafeSkillPath(String)

        var errorDescription: String? {
            switch self {
            case .runningFromHomeDirectory:
                return "Cannot install tools from the home directory. Please run luca install from within a project directory."
            case .unsafeSkillPath(let path):
                return "Refusing to install skill file '\(path)': its path escapes the skill directory."
            }
        }
    }

    private let fileManager: FileManaging
    private let printer: Printing
    private let linkedToolsLister: LinkedToolsLister
    private let unlinker: Unlinker
    private let ignoreArchitectureCheck: Bool
    private let ignoreUnsafeArchiveEntries: Bool
    private let quiet: Bool
    private let noora: Noorable
    private let toolInstaller: ToolInstalling
    private let skillInstaller: SkillInstalling
    private let skillDownloader: SkillDownloading
    private let skillSymLinker: SkillSymLinking
    private let specLoader: SpecLoading

    public init(
        fileManager: FileManaging,
        ignoreArchitectureCheck: Bool,
        ignoreUnsafeArchiveEntries: Bool = false,
        quiet: Bool = false,
        printer: Printing,
        noora: Noorable
    ) {
        self.init(
            fileManager: fileManager,
            ignoreArchitectureCheck: ignoreArchitectureCheck,
            ignoreUnsafeArchiveEntries: ignoreUnsafeArchiveEntries,
            quiet: quiet,
            printer: printer,
            noora: noora,
            toolInstaller: nil,
            skillInstaller: nil,
            skillDownloader: nil,
            skillSymLinker: nil,
            specLoader: nil
        )
    }

    init(
        fileManager: FileManaging,
        ignoreArchitectureCheck: Bool,
        ignoreUnsafeArchiveEntries: Bool = false,
        quiet: Bool = false,
        printer: Printing,
        noora: Noorable = Noora(),
        toolInstaller: ToolInstalling? = nil,
        skillInstaller: SkillInstalling? = nil,
        skillDownloader: SkillDownloading? = nil,
        skillSymLinker: SkillSymLinking? = nil,
        specLoader: SpecLoading? = nil
    ) {
        self.fileManager = fileManager
        self.printer = printer
        self.linkedToolsLister = LinkedToolsLister(fileManager: fileManager)
        self.unlinker = Unlinker(fileManager: fileManager, printer: printer)
        self.ignoreArchitectureCheck = ignoreArchitectureCheck
        self.ignoreUnsafeArchiveEntries = ignoreUnsafeArchiveEntries
        self.quiet = quiet
        self.noora = noora
        self.toolInstaller = toolInstaller ?? ToolInstaller(
            fileManager: fileManager,
            ignoreArchitectureCheck: ignoreArchitectureCheck,
            ignoreUnsafeArchiveEntries: ignoreUnsafeArchiveEntries,
            printer: printer
        )
        self.skillInstaller = skillInstaller ?? SkillInstaller()
        self.skillDownloader = skillDownloader ?? SkillDownloader()
        self.skillSymLinker = skillSymLinker ?? SkillSymLinker(fileManager: fileManager)
        self.specLoader = specLoader ?? SpecLoader(fileManager: .default)
    }

    /// Installs tools based on the specified installation type.
    ///
    /// - Parameter installationType: Specifies how to determine which tools to install.
    ///   Can be either `.spec` to read from a Lucafile, or `.individual`/`.individualInline`
    ///   to install directly from a GitHub release.
    /// - Throws: An error if downloading, extracting, or linking fails.
    public func install(installationType: ToolInstallationType) async throws {
        guard fileManager.currentDirectoryPath != fileManager.homeDirectoryForCurrentUser.path else {
            throw InstallerError.runningFromHomeDirectory
        }
        if quiet {
            try await installQuietly(installationType: installationType)
        } else {
            try await installVerbose(installationType: installationType)
        }
    }
    
    /// Installs skills based on the specified installation type.
    ///
    /// - Parameters:
    ///   - installationType: Specifies how to determine which skills to install.
    ///     Can be `.spec` to read from a Lucafile, or `.individual` to install directly from a repository.
    ///   - useNpx: When `true`, routes installation through the npx-based ``SkillInstalling`` path
    ///     instead of Luca's native pipeline (``SkillDownloading`` + ``SkillSymLinking``).
    ///   - isGlobal: When `true`, caches skills to `~/.luca/skills/` and symlinks to each agent's global path.
    /// - Throws: An error if downloading, extracting, or linking fails.
    public func install(installationType: SkillInstallationType, useNpx: Bool = false, isGlobal: Bool = false) async throws {
        if quiet {
            try await installQuietly(installationType: installationType, useNpx: useNpx, isGlobal: isGlobal)
        } else {
            try await installVerbose(installationType: installationType, useNpx: useNpx, isGlobal: isGlobal)
        }
    }
    
    // MARK: - Private
    
    private func installQuietly(installationType: ToolInstallationType) async throws {
        let dataDownloader = DataDownloader(session: .shared)
        let releaseInfoProvider = ReleaseInfoProvider(dataDownloader: dataDownloader)
        let toolFactory = ToolFactory(releaseInfoProvider: releaseInfoProvider, specLoader: specLoader)
        let tools = try await toolFactory.toolsForInstallationType(installationType)

        // Unlink orphaned tools only when installing from a spec
        if case .spec = installationType {
            try unlinkOrphanedTools(specTools: tools)
        }

        guard !tools.isEmpty else { return }

        try await noora.progressStep(
            message: "Installing tools",
            successMessage: "Tools have been installed for the current project",
            errorMessage: "Failed to install tools",
            showSpinner: true
        ) { updateMessage in
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
    
    private func installQuietly(installationType: SkillInstallationType, useNpx: Bool, isGlobal: Bool = false) async throws {
        let skillsInfoFactory = SkillsInfoFactory(specLoader: specLoader)
        let skillsInfo = try await skillsInfoFactory.skillsInfoForInstallationType(installationType)
        guard !skillsInfo.skillSets.isEmpty else { return }

        let scope = isGlobal ? "globally" : "for the current project"
        try await noora.progressStep(
            message: "Installing skills",
            successMessage: "Skills have been installed \(scope)",
            errorMessage: "Failed to install skills",
            showSpinner: true
        ) { updateMessage in
            // Compute resolvedAgents once (same for all SkillSets)
            let resolvedAgents: [AgentInfo]
            if let agentIds = skillsInfo.agents {
                resolvedAgents = AgentRegistry.agents(for: agentIds)
            } else {
                resolvedAgents = AgentRegistry.all
            }
            for skillSet in skillsInfo.skillSets {
                updateMessage("Installing skills from \(skillSet.repository)")
                try await install(skillSet, agents: skillsInfo.agents, useNpx: useNpx, isGlobal: isGlobal, resolvedAgents: resolvedAgents)
            }
            if !useNpx && !isGlobal {
                let gitIgnoreManager = GitIgnoreManager(fileManager: fileManager, printer: printer)
                try gitIgnoreManager.ensureGitIgnoreIncludesSkillFolders(agents: resolvedAgents)
            }
        }
    }

    private func installVerbose(installationType: SkillInstallationType, useNpx: Bool, isGlobal: Bool = false) async throws {
        let skillsInfoFactory = SkillsInfoFactory(specLoader: specLoader)

        printer.printFormatted("\(.info("🧠 Detecting skills to install..."))")

        let skillsInfo = try await skillsInfoFactory.skillsInfoForInstallationType(installationType)
        let scope = isGlobal ? "globally" : "for the current project"
        if !skillsInfo.skillSets.isEmpty {
            printer.printFormatted("\(.info("🧠 Installing skills for the current project."))")
            printer.printFormatted("")
            // Compute resolvedAgents once (same for all SkillSets)
            let resolvedAgents: [AgentInfo]
            if let agentIds = skillsInfo.agents {
                resolvedAgents = AgentRegistry.agents(for: agentIds)
            } else {
                resolvedAgents = AgentRegistry.all
            }
            for skillSet in skillsInfo.skillSets {
                try await install(skillSet, agents: skillsInfo.agents, useNpx: useNpx, isGlobal: isGlobal, resolvedAgents: resolvedAgents)
                printer.printFormatted("")
            }
            if !useNpx && !isGlobal {
                let gitIgnoreManager = GitIgnoreManager(fileManager: fileManager, printer: printer)
                try gitIgnoreManager.ensureGitIgnoreIncludesSkillFolders(agents: resolvedAgents)
            }
            printer.printFormatted("\(.success("🚀 Skills have been installed \(scope)."))")
        } else {
            printer.printFormatted("\(.muted("🫥 No skills have been installed \(scope)."))")
        }
    }

    private func install(_ skillSet: SkillSet, agents: [String]?, useNpx: Bool, isGlobal: Bool = false, resolvedAgents: [AgentInfo]) async throws {
        printer.printFormatted("\(.raw("🧩 Installing skills from \(skillSet.repository)..."))")
        if useNpx {
            try await skillInstaller.install(skillSet: skillSet, agents: agents)
        } else {
            let skills = try await skillDownloader.download(skillSet: skillSet)
            for (name, files) in skills {
                let skillFolder = isGlobal
                    ? fileManager.globalSkillsCacheFolder.appending(component: name)
                    : fileManager.skillsCacheFolder.appending(component: name)
                try fileManager.createDirectory(at: skillFolder, withIntermediateDirectories: true)
                for skillFile in files {
                    let filePath = skillFolder.appendingPathComponent(skillFile.relativePath)
                    // Defence-in-depth: a skill's file paths come from a remote repository, so make
                    // sure none of them resolve outside the skill directory (path traversal) before
                    // writing anything to disk.
                    guard isContained(filePath, within: skillFolder) else {
                        throw InstallerError.unsafeSkillPath(skillFile.relativePath)
                    }
                    let parentDir = filePath.deletingLastPathComponent()
                    try fileManager.createDirectory(at: parentDir, withIntermediateDirectories: true)
                    _ = fileManager.createFile(atPath: filePath.path, contents: skillFile.content)
                }
                try skillSymLinker.setSymLink(skillName: name, version: skillSet.version, agents: resolvedAgents, isGlobal: isGlobal)
            }
        }
        let scope = isGlobal ? "globally" : "for the current project"
        printer.printFormatted("\(.primary("🙌 Skills from \(skillSet.repository) installed \(scope)."))")
    }

    /// Returns whether `url` lexically resolves to a location inside `base`.
    ///
    /// Uses `standardizedFileURL` so that `..` components are collapsed without touching the file
    /// system, making this safe to call before the file exists.
    private func isContained(_ url: URL, within base: URL) -> Bool {
        let basePath = base.standardizedFileURL.path
        let candidatePath = url.standardizedFileURL.path
        return candidatePath == basePath || candidatePath.hasPrefix(basePath + "/")
    }

    private func isToolInstalled(_ tool: Tool) -> Bool {
        let expectedBinaryLocation: URL = {
            let versionFolder = fileManager.toolsFolder
                .appending(components: tool.name, tool.version)
            if let desiredBinaryName = tool.desiredBinaryName {
                return versionFolder
                    .appending(component: desiredBinaryName)
            }
            if let binaryPath = tool.binaryPath {
                return versionFolder
                    .appending(components: binaryPath)
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
