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
        abstract: "Install tools from a spec file or GitHub releases.",
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
        Defaults to './Lucafile' in the current directory if not specified.
        Examples:
          luca install
          luca install --spec ./config/Lucafile
        """,
        valueName: "path"
    ))
    var spec: String?
    
    @Argument(help: ArgumentHelp(
        "Tool to install in 'org/repo@version' format.",
        discussion: """
        Examples:
          luca install TogglesPlatform/Toggles@1.0.0
          luca install krzysztofzablocki/Sourcery@2.2.7 --asset sourcery-2.2.7.zip
        """,
        valueName: "org/repo@version"
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

    func run() async throws {
        let printer: Printing = quiet ? QuietPrinter() : Printer()
        Header(printer: printer).printHeader()

        let fileManager = FileManagerWrapper(fileManager: .default)
        let installer = Installer(
            fileManager: fileManager,
            ignoreArchitectureCheck: ignoreArchCheck,
            quiet: quiet,
            printer: printer
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
        let installationType = try installationType(for: arguments, fileManager: fileManager)
        
        let gitIgnoreManager = GitIgnoreManager(fileManager: fileManager, printer: printer)
        try gitIgnoreManager.ensureGitIgnoreIncludesSymlinksFolder()
        
        if installPostCheckoutGitHook {
            let gitHookInstaller = GitHookInstaller(fileManager: fileManager, printer: printer)
            try gitHookInstaller.installPostCheckoutHook()
        }
        
        try await installer.install(installationType: installationType)
    }
    
    /// Path to the spec file: either explicit via `--spec` or default to `Constants.specFile` in current directory.
    /// When no exact `Lucafile` exists, discovers files with the `Lucafile` prefix and prompts the user to pick one.
    private func specPath(providedSpec: String?, fileManager: FileManaging) throws -> URL {
        if let providedSpec {
            return URL(fileURLWithPath: providedSpec)
        }

        let currentDirectory = URL(fileURLWithPath: fileManager.currentDirectoryPath)
        let defaultPath = currentDirectory.appending(component: Constants.specFile)

        // If exact Lucafile exists, use it directly.
        if fileManager.fileExists(atPath: defaultPath.path) {
            return defaultPath
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
            let noora = Noora()
            let options = candidates.map { $0.lastPathComponent }
            let selected: String = noora.singleChoicePrompt(
                title: "Select spec",
                question: "Multiple \(Constants.specFile) found. Which one do you want to use?",
                options: options
            )
            return currentDirectory.appending(component: selected)
        }
    }
    
    private func installationType(for arguments: Arguments, fileManager: FileManaging) throws -> InstallationType {
        switch (arguments.spec, arguments.identifier, arguments.asset, arguments.name, arguments.version, arguments.url, arguments.binaryPath, arguments.desiredBinaryName, arguments.checksum, arguments.algorithm) {
        case (let spec, .none, .none, .none, .none, .none, .none, .none, .none, .none):
            let specPath = try specPath(providedSpec: spec, fileManager: fileManager)
            return .spec(specPath: specPath)
        case (.none, .some(let identifier), let asset, .none, .none, .none, let binaryPath, let desiredBinaryName, let checksum, let algorithm):
            return .individual(identifier: identifier, asset: asset, binaryPath: binaryPath, desiredBinaryName: desiredBinaryName, checksum: checksum, algorithm: algorithm)
        case (.none, .none, .none, .some(let name), .some(let version), .some(let url), let binaryPath, let desiredBinaryName, let checksum, let algorithm):
            return .individualInline(name: name, version: version, url: url, binaryPath: binaryPath, desiredBinaryName: desiredBinaryName, checksum: checksum, algorithm: algorithm)
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
