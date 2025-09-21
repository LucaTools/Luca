//  InstallCommand.swift

import ArgumentParser
import Foundation
import LucaCore
import Noora
import Yams

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
        abstract: """
Install versions of tools defined in a spec file or directly from GitHub releases.

Example of usages:
  
# From a spec

luca install
luca install --spec ./Lucafile
  
# Individual installations

luca install TogglesPlatform/Toggles@1.0.0
luca install krzysztofzablocki/Sourcery@2.2.7
  --asset sourcery-2.2.7.zip
  --binary-path bin/sourcery
  
# Inline installations

luca install
  --name ToggleGen
  --version 1.0.0
  --url https://github.com/TogglesPlatform/ToggleGen/releases/download/1.0.0/ToggleGen-macOS-universal-binary.zip

luca install
  --name Sourcery
  --version 2.2.7
  --url https://github.com/krzysztofzablocki/Sourcery/releases/download/2.2.7/sourcery-2.2.7.zip
  --binary-path bin/sourcery
"""
    )

    @Option(name: .long, help: "The location of the spec file.")
    var spec: String?
    
    @Argument(help: "Tool to install in format 'organization/repository@version'")
    var identifier: String?
    
    @Option(help: "Name of the tool to install.")
    var name: String?
    
    @Option(help: "Version of the tool to install.")
    var version: String?
    
    @Option(help: "URL of the asset for the tool to install.")
    var url: String?
    
    @Option(help: "Filename of the asset associated with the release")
    var asset: String?
    
    @Option(help: "Binary path for the asset associated with the release")
    var binaryPath: String?

    private var noora: Noorable { Noora() }
    
    func run() async throws {
        Header(noora: noora).printHeader()

        let fileManager = FileManagerWrapper(fileManager: .default)
        let installer = Installer(fileManager: fileManager, noora: noora)
        let arguments = Arguments(
            spec: spec,
            identifier: identifier,
            asset: asset,
            name: name,
            version: version,
            url: try toolUrl(for: url),
            binaryPath: binaryPath
        )
        let installationType = try installationType(for: arguments)
        try await installer.install(installationType: installationType)
    }
    
    /// Path to the spec file: either explicit via `--spec` or default to `Constants.specFile` in current directory.
    private func specPath(providedSpec: String?) -> URL {
        if let providedSpec {
            return URL(fileURLWithPath: providedSpec)
        }
        return URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
            .appending(component: Constants.specFile)
    }
    
    private func installationType(for arguments: Arguments) throws -> InstallationType {
        switch (arguments.spec, arguments.identifier, arguments.asset, arguments.name, arguments.version, arguments.url, arguments.binaryPath) {
        case (let spec, .none, .none, .none, .none, .none, .none):
            let specPath = specPath(providedSpec: spec)
            return .spec(specPath: specPath)
        case (.none, .some(let identifier), let asset, .none, .none, .none, let binaryPath):
            return .individual(identifier: identifier, asset: asset, binaryPath: binaryPath)
        case (.none, .none, .none, .some(let name), .some(let version), .some(let url), let binaryPath):
            return .individualInline(name: name, version: version, url: url, binaryPath: binaryPath)
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
