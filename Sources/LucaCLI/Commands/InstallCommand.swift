//  InstallCommand.swift

import ArgumentParser
import Foundation
import LucaCore
import Noora
import Yams

extension ChecksumAlgorithm: ExpressibleByArgument {}

/// Installs the versions of tools specified by a YAML spec file.
struct InstallCommand: AsyncParsableCommand {
    
    enum InstallCommandError: Error, LocalizedError {
        case cannotConstructUrl(String)
        case invalidCombinationOfArguments(Arguments)

        var errorDescription: String? {
            switch self {
            case .cannotConstructUrl(let value):
                return "Cannot construct URL from String '\(value)'."
            case .invalidCombinationOfArguments(let arguments):
                return "Invalid combination of arguments. Please rely on the documentation to see examples of invocations (e.g. use --help).\nGot the following parameters:\n\(String(describing: arguments))."
            }
        }
    }
    
    static let configuration = CommandConfiguration(
        commandName: "install",
        abstract: "Install tools or skills from a spec file or GitHub releases.",
        discussion: """
        Supports three installation modes:
        - Spec file: Install all tools defined in a Lucafile
        - Individual: Install from GitHub using org/repo@version format
        - Inline: Install from a direct URL with explicit parameters
        
        See parameter help for detailed examples.
        """
    )

    @Option(name: .long, help: ArgumentHelp(
        "Path to the spec file.",
        discussion: """
        Defaults to './Lucafile' or './Lucafile.yml' in the current directory if not specified.
        Examples:
          luca install
          luca install --spec ./config/Lucafile
          luca install --spec ./config/Lucafile.yml
        """,
        valueName: "path"
    ))
    var spec: String?
    
    @Argument(help: ArgumentHelp(
        "Tool ('org/repo@version') or skill ('org/repo' or URL) to install.",
        discussion: """
        Tool examples:
          luca install TogglesPlatform/Toggles@1.0.0
          luca install krzysztofzablocki/Sourcery@2.2.7 --asset sourcery-2.2.7.zip

        Skill examples:
          luca install AvdLee/Swift-Concurrency-Agent-Skill
          luca install vercel-labs/agent-skills --skill find-skills
        """,
        valueName: "identifier"
    ))
    var identifier: String?
    
    @Option(help: ArgumentHelp(
        "Name of the tool (inline mode).",
        discussion: """
        Requires --version and --url.
        Example:
          luca install --name ToggleGen --version 1.0.0 \\
            --url https://github.com/.../ToggleGen.zip
        """,
        valueName: "tool-name"
    ))
    var name: String?
    
    @Option(help: ArgumentHelp(
        "Version of the tool (inline mode).",
        discussion: "Requires --name and --url.",
        valueName: "version"
    ))
    var version: String?
    
    @Option(help: ArgumentHelp(
        "URL of the asset to download (inline mode).",
        discussion: "Requires --name and --version.",
        valueName: "url"
    ))
    var url: String?
    
    @Option(help: ArgumentHelp(
        "Filename of the release asset to download.",
        discussion: """
        Use when the release contains multiple assets.
        Example:
          luca install krzysztofzablocki/Sourcery@2.2.7 \\
            --asset sourcery-2.2.7.zip
        """,
        valueName: "filename"
    ))
    var asset: String?
    
    @Option(help: ArgumentHelp(
        "Path to the executable inside the archive.",
        discussion: """
        Required when the binary is nested within the archive.
        Example:
          --binary-path bin/sourcery
        """,
        valueName: "path"
    ))
    var binaryPath: String?
    
    @Option(help: ArgumentHelp(
        "Local name for the installed binary.",
        discussion: """
        Useful when the downloaded file has a different name.
        Example:
          luca install firebase/firebase-tools@v14.12.1 \\
            --desired-binary-name firebase
        """,
        valueName: "name"
    ))
    var desiredBinaryName: String?
    
    @Option(help: ArgumentHelp(
        "Expected checksum for integrity verification.",
        discussion: """
        Use with --algorithm.
        Example:
          --checksum e0a6540d01434f436335a9f48405ffd00802...
        """,
        valueName: "hash"
    ))
    var checksum: String?
    
    @Option(help: ArgumentHelp(
        "Hash algorithm for checksum verification.",
        valueName: "algorithm"
    ))
    var algorithm: ChecksumAlgorithm?
    
    @Flag(help: ArgumentHelp(
        "Skip architecture compatibility validation.",
        discussion: """
        Use for platform-independent executables.
        Example:
          luca install firebase/firebase-tools@v14.12.1 \\
            --desired-binary-name firebase \\
            --ignore-arch-check
        """
    ))
    var ignoreArchCheck: Bool = false
    
    @Flag(inversion: .prefixedNo, help: ArgumentHelp(
        "Install the post-checkout git hook.",
        discussion: """
        Enabled by default. Automatically runs 'luca install' after git checkout.
        Use --no-install-post-checkout-git-hook to disable.
        """
    ))
    var installPostCheckoutGitHook: Bool = true
    
    @Flag(help: ArgumentHelp(
        "Suppress output except final success message.",
        discussion: "Useful for CI/CD pipelines or scripting."
    ))
    var quiet: Bool = false

    @Flag(help: ArgumentHelp(
        "Install only binary tools; skip skills.",
        discussion: """
        For spec-based installs only (no identifier argument).
        Cannot be combined with --only-skills.
        Example:
          luca install --only-tools
        """
    ))
    var onlyTools: Bool = false

    @Flag(help: ArgumentHelp(
        "Install only skills; skip binary tools.",
        discussion: """
        For spec-based installs only (no identifier argument).
        Cannot be combined with --only-tools.
        Example:
          luca install --only-skills
        """
    ))
    var onlySkills: Bool = false

    @Flag(name: .customLong("use-npx"), help: ArgumentHelp(
        "Use Vercel Labs' npx-based skills tool instead of the native pipeline.",
        discussion: """
        Routes skill installation through `npx skills add` (Vercel Labs' skills tool)
        instead of Luca's built-in native pipeline.
        Requires Node.js and npx to be available.
        Example:
          luca install --only-skills --use-npx
          luca install vercel-labs/agent-skills --use-npx
        """
    ))
    var useNpx: Bool = false

    @Option(name: .customLong("skill"), help: ArgumentHelp(
        "Specific skill name to install (repeatable).",
        discussion: """
        Install only the named skills from the repository.
        Can be specified multiple times.
        Example:
          luca install AvdLee/Swift-Concurrency-Agent-Skill --skill swift-concurrency
        """,
        valueName: "name"
    ))
    var skills: [String] = []

    @Option(name: .customLong("agent"), help: ArgumentHelp(
        "Agent to install skills for (repeatable).",
        discussion: """
        Override the agents: list from the Lucafile.
        Can be specified multiple times.
        Example:
          luca install --only-skills --agent claude-code --agent cursor
        """,
        valueName: "agent-id"
    ))
    var agents: [String] = []

    func run() async throws {
        let noora = Noora(terminal: Terminal(signalBehavior: .none))
        let printer: Printing = quiet ? QuietPrinter() : Printer(noora: noora)
        Header(printer: printer).printHeader()

        let fileManager = FileManagerWrapper(fileManager: .default)
        let installer = Installer(
            fileManager: fileManager,
            ignoreArchitectureCheck: ignoreArchCheck,
            quiet: quiet,
            printer: printer,
            noora: noora
        )
        let arguments = Arguments(
            spec: spec,
            identifier: identifier,
            asset: asset,
            name: name,
            version: version,
            url: try toolUrl(for: url),
            binaryPath: binaryPath,
            desiredBinaryName: desiredBinaryName,
            checksum: checksum,
            algorithm: algorithm
        )
        let gitIgnoreManager = GitIgnoreManager(fileManager: fileManager, printer: printer)
        try gitIgnoreManager.ensureGitIgnoreIncludesSymlinksFolder()

        if installPostCheckoutGitHook {
            let gitHookInstaller = GitHookInstaller(fileManager: fileManager, printer: printer)
            try gitHookInstaller.installPostCheckoutHook()
        }

        let installMode: InstallMode
        if let id = identifier {
            installMode = id.contains("@") ? .toolsOnly : .skillsOnly
        } else {
            installMode = onlyTools ? .toolsOnly : onlySkills ? .skillsOnly : .all
        }

        switch installMode {
        case .toolsOnly:
            let toolInstallationType = try toolInstallationType(for: arguments, fileManager: fileManager, noora: noora)
            try await installer.install(installationType: toolInstallationType)
        case .skillsOnly:
            let skillInstallationType = try skillInstallationType(for: arguments, fileManager: fileManager, noora: noora)
            try await installer.install(installationType: skillInstallationType, useNpx: useNpx)
        case .all:
            let toolInstallationType = try toolInstallationType(for: arguments, fileManager: fileManager, noora: noora)
            try await installer.install(installationType: toolInstallationType)
            let skillInstallationType = try skillInstallationType(for: arguments, fileManager: fileManager, noora: noora)
            try await installer.install(installationType: skillInstallationType, useNpx: useNpx)
        }
    }
    
    func validate() throws {
        guard !(onlyTools && onlySkills) else {
            throw InstallCommandError.invalidCombinationOfArguments(Arguments(
                spec: spec,
                identifier: identifier,
                asset: asset,
                name: name,
                version: version,
                url: try toolUrl(for: url),
                binaryPath: binaryPath,
                desiredBinaryName: desiredBinaryName,
                checksum: checksum,
                algorithm: algorithm
            ))
        }
        if identifier != nil && (onlyTools || onlySkills) {
            throw InstallCommandError.invalidCombinationOfArguments(Arguments(
                spec: spec,
                identifier: identifier,
                asset: asset,
                name: name,
                version: version,
                url: try toolUrl(for: url),
                binaryPath: binaryPath,
                desiredBinaryName: desiredBinaryName,
                checksum: checksum,
                algorithm: algorithm
            ))
        }
    }
    
    // MARK: - Private
    
    /// Path to the spec file: either explicit via `--spec` or default to `Constants.specFile` (or `Lucafile.yml`) in current directory.
    /// When no exact `Lucafile` or `Lucafile.yml` exists, discovers files with the `Lucafile` prefix and prompts the user to pick one.
    private func specPath(providedSpec: String?, fileManager: FileManaging, noora: Noorable) throws -> URL {
        if let providedSpec {
            return URL(fileURLWithPath: providedSpec)
        }

        let currentDirectory = URL(fileURLWithPath: fileManager.currentDirectoryPath)
        let defaultPath = currentDirectory.appending(component: Constants.specFile)

        // If Lucafile exists, use it as the default.
        if fileManager.fileExists(atPath: defaultPath.path) {
            return defaultPath
        }

        // If Lucafile.yml exists, use it as the default.
        let ymlPath = currentDirectory.appending(component: "\(Constants.specFile).\(Constants.ymlExtension)")
        if fileManager.fileExists(atPath: ymlPath.path) {
            return ymlPath
        }

        // Auto-discover files with the Lucafile prefix.
        let finder = SpecFinder(fileManager: fileManager)
        let candidates = try finder.findSpecFiles(in: currentDirectory)

        switch candidates.count {
        case 0:
            // Return default path; will trigger a missing-spec error downstream.
            return defaultPath
        case 1:
            return candidates[0]
        default:
            let options = candidates.map { $0.lastPathComponent }
            let selected: String = noora.singleChoicePrompt(
                title: "Select spec",
                question: "Multiple \(Constants.specFile) found. Which one do you want to use?",
                options: options
            )
            return currentDirectory.appending(component: selected)
        }
    }
    
    private func toolInstallationType(for arguments: Arguments, fileManager: FileManaging, noora: Noorable) throws -> ToolInstallationType {
        switch (arguments.spec, arguments.identifier, arguments.asset, arguments.name, arguments.version, arguments.url, arguments.binaryPath, arguments.desiredBinaryName, arguments.checksum, arguments.algorithm) {
        case (let spec, .none, .none, .none, .none, .none, .none, .none, .none, .none):
            let specPath = try specPath(providedSpec: spec, fileManager: fileManager, noora: noora)
            return .spec(specPath: specPath)
        case (.none, .some(let identifier), let asset, .none, .none, .none, let binaryPath, let desiredBinaryName, let checksum, let algorithm):
            return .individual(identifier: identifier, asset: asset, binaryPath: binaryPath, desiredBinaryName: desiredBinaryName, checksum: checksum, algorithm: algorithm)
        case (.none, .none, .none, .some(let name), .some(let version), .some(let url), let binaryPath, let desiredBinaryName, let checksum, let algorithm):
            return .individualInline(name: name, version: version, url: url, binaryPath: binaryPath, desiredBinaryName: desiredBinaryName, checksum: checksum, algorithm: algorithm)
        default:
            throw InstallCommandError.invalidCombinationOfArguments(arguments)
        }
    }
    
    private func skillInstallationType(for arguments: Arguments, fileManager: FileManaging, noora: Noorable) throws -> SkillInstallationType {
        if let identifier = arguments.identifier {
            return .individual(
                repository: identifier,
                skillNames: skills,
                agents: agents.isEmpty ? nil : agents
            )
        }
        switch (arguments.spec, arguments.identifier, arguments.asset, arguments.name, arguments.version, arguments.url, arguments.binaryPath, arguments.desiredBinaryName, arguments.checksum, arguments.algorithm) {
        case (let spec, .none, .none, .none, .none, .none, .none, .none, .none, .none):
            let specPath = try specPath(providedSpec: spec, fileManager: fileManager, noora: noora)
            return .spec(specPath: specPath)
        default:
            throw InstallCommandError.invalidCombinationOfArguments(arguments)
        }
    }
    
    private func toolUrl(for urlString: String?) throws -> URL? {
        if let urlString {
            guard let toolUrl = URL(string: urlString) else {
                throw InstallCommandError.cannotConstructUrl(urlString)
            }
            return toolUrl
        } else {
            return nil
        }
    }
}
