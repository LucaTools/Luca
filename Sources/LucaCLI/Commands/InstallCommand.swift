//  InstallCommand.swift

import Foundation
import ArgumentParser
import Yams
import LucaCore

/// Installs the versions of tools specified by a YAML spec file.
struct InstallCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "install",
        abstract: "Install versions of the tools defined in a spec file and makes them discoverable in the PATH."
    )

    @Option(name: .long, help: "The location of the spec file.")
    var spec: String?

    var fileManager: FileManager { FileManager.default }

    func run() async throws {
        let spec = try loadSpec(at: specPath)
        let installer = Installer(fileManager: fileManager)
        try await installer.install(from: spec)
    }

    /// Load spec data from disk and decode YAML into `Spec`.
    private func loadSpec(at path: URL) throws -> Spec {
        let data = try Data(contentsOf: path)
        return try YAMLDecoder().decode(Spec.self, from: data)
    }

    /// Path to the spec file: either explicit --spec or default in current directory.
    private var specPath: URL {
        if let spec { return URL(fileURLWithPath: spec) }
        return URL(fileURLWithPath: fileManager.currentDirectoryPath)
            .appending(component: Constants.specFile)
    }

    func validate() throws {
        guard fileManager.fileExists(atPath: specPath.path) else {
            throw ValidationError("Spec file not found at \(specPath.path).")
        }
    }
}
