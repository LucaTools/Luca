//  InitCommand.swift

import ArgumentParser
import Foundation
import LucaCore
import Noora

/// Creates a new spec file (Lucafile) in the current directory or the global config location.
struct InitCommand: AsyncParsableCommand {

    enum InitCommandError: Error, LocalizedError, Equatable {
        case abortedByUser

        var errorDescription: String? {
            switch self {
            case .abortedByUser:
                return "Aborted."
            }
        }
    }

    @OptionGroup var commonFlags: CommonFlags

    static let configuration = CommandConfiguration(
        commandName: "init",
        abstract: "Create a new spec file to define your tools and skills.",
        discussion: """
        Interactively creates a Lucafile (or Toolfile / Skillfile) pre-populated with
        commented examples. You choose whether the file is created in the current
        project directory or in the global config location (~/.config/luca/).

        Examples:
          luca init
        """
    )

    func run() async throws {
        let noora = Noora(terminal: Terminal(signalBehavior: .none))
        let printer: Printing = Printer(noora: noora)
        Header(printer: printer).printHeader()

        let fileManager = FileManagerWrapper(fileManager: .default)
        let specInitializer = SpecInitializer(fileManager: fileManager)

        // 1. Ask where to create the file.
        let locationLocal = "Current directory"
        let locationGlobal = "Global (~/.config/luca/)"
        let selectedLocation: String = noora.singleChoicePrompt(
            title: "Location",
            question: "Where do you want to create the spec file?",
            options: [locationLocal, locationGlobal]
        )
        let location: SpecInitializer.Location = selectedLocation == locationGlobal ? .global : .local

        // 2. Ask what to name the file.
        let selectedName: String = noora.singleChoicePrompt(
            title: "Filename",
            question: "What should the spec file be named?",
            options: Constants.specFiles
        )

        // 3. Try to create; if file exists ask to overwrite.
        let targetURL: URL
        do {
            targetURL = try specInitializer.createSpec(named: selectedName, location: location)
        } catch SpecInitializer.SpecInitializerError.fileAlreadyExists(let path) {
            let overwrite = noora.yesOrNoChoicePrompt(
                title: "File exists",
                question: "\(path) already exists. Overwrite?",
                defaultAnswer: false,
                description: nil,
                collapseOnSelection: true
            )
            guard overwrite else {
                throw InitCommandError.abortedByUser
            }
            targetURL = try specInitializer.createSpec(named: selectedName, location: location, overwrite: true)
        }

        printer.printFormatted("\(.success("Created \(targetURL.path)"))")
    }
}
