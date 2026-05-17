//  RunCommand.swift

import ArgumentParser
import Foundation
import LucaCore
import Noora

/// Executes a pipeline of shell tasks defined in a YAML file.
struct RunCommand: AsyncParsableCommand {

    enum RunCommandError: Error, LocalizedError, Equatable {
        case pipelineNotFound(String)

        var errorDescription: String? {
            switch self {
            case .pipelineNotFound(let name):
                return """
                No pipeline file found for '\(name)'. \
                Searched: \(name).yml, \(name), \
                \(Constants.pipelinesFolder)/\(name).yml, \(Constants.pipelinesFolder)/\(name).
                """
            }
        }
    }

    static let configuration = CommandConfiguration(
        commandName: "run",
        abstract: "Execute a pipeline of shell tasks.",
        discussion: """
        Loads a YAML pipeline file and executes its tasks sequentially.

        File lookup for `luca run <name>` (in order):
          1. ./<name>.yml
          2. ./<name>
          3. ./pipelines/<name>.yml
          4. ./pipelines/<name>

        Use --file to specify an explicit path instead.

        Examples:
          luca run ci
          luca run deploy --dry-run
          luca run --file pipelines/release.yml
        """
    )

    @OptionGroup var commonFlags: CommonFlags

    @Argument(help: ArgumentHelp(
        "Name of the pipeline to run.",
        discussion: """
        Resolved against the current directory and ./pipelines/ using convention-based lookup.
        Mutually exclusive with --file.
        """,
        valueName: "name"
    ))
    var name: String?

    @Option(name: .customLong("file"), help: ArgumentHelp(
        "Explicit path to a pipeline YAML file.",
        discussion: "Skips the convention-based file lookup. Mutually exclusive with <name>.",
        valueName: "path"
    ))
    var file: String?

    @Flag(help: ArgumentHelp(
        "Validate tools and print tasks without executing.",
        discussion: "Runs the pre-flight check and prints all tasks with tool availability, but does not execute any commands."
    ))
    var dryRun: Bool = false

    func validate() throws {
        guard name != nil || file != nil else {
            throw ValidationError("Missing required argument. Provide <name> or --file <path>.")
        }
        if name != nil && file != nil {
            throw ValidationError("<name> and --file are mutually exclusive.")
        }
    }

    func run() async throws {
        let noora = Noora(terminal: Terminal(signalBehavior: .none))
        let printer: Printing = Printer(noora: noora)
        Header(printer: printer).printHeader()

        let fileManager = FileManagerWrapper(fileManager: .default)
        let invocationDirectory = URL(fileURLWithPath: fileManager.currentDirectoryPath)

        let pipelinePath: URL
        if let explicitFile = file {
            pipelinePath = URL(fileURLWithPath: explicitFile)
        } else if let pipelineName = name {
            pipelinePath = try resolvePipelinePath(name: pipelineName, in: invocationDirectory, fileManager: fileManager)
        } else {
            throw ValidationError("Missing required argument.")
        }

        let loader = PipelineLoader()
        let pipeline = try loader.loadPipeline(at: pipelinePath)
        let validator = PipelineValidator(fileManager: fileManager)

        if dryRun {
            printDryRun(pipeline: pipeline, pipelinePath: pipelinePath, validator: validator, printer: printer)
            return
        }

        try validator.validate(pipeline)

        let runner = PipelineRunner(printer: printer)
        try await runner.run(pipeline, currentDirectoryURL: invocationDirectory)

    }

    // MARK: - Private

    private func resolvePipelinePath(name: String, in directory: URL, fileManager: FileManaging) throws -> URL {
        let candidates: [URL] = [
            directory.appending(component: "\(name).\(Constants.ymlExtension)"),
            directory.appending(component: name),
            directory.appending(components: Constants.pipelinesFolder, "\(name).\(Constants.ymlExtension)"),
            directory.appending(components: Constants.pipelinesFolder, name)
        ]
        for candidate in candidates {
            if fileManager.fileExists(atPath: candidate.path) {
                return candidate
            }
        }
        throw RunCommandError.pipelineNotFound(name)
    }

    private func printDryRun(pipeline: Pipeline, pipelinePath: URL, validator: PipelineValidating, printer: Printing) {
        let displayName = name ?? pipelinePath.lastPathComponent
        printer.printFormatted("\(.accent("[DRY RUN] Pipeline: \(displayName)"))")
        printer.printFormatted("\(.raw(""))")

        let allResults = validator.toolCheckResults(for: pipeline)

        for (index, task) in pipeline.tasks.enumerated() {
            let taskResults = index < allResults.count ? allResults[index] : []
            printer.printFormatted("\(.primary("  Task \(index + 1): \(task.name)"))")
            printer.printFormatted("\(.raw("    Command: \(task.command)"))")

            if taskResults.isEmpty {
                printer.printFormatted("\(.raw("    Tools:   (none)"))")
            } else {
                for result in taskResults {
                    let mark = result.available ? "✓" : "✗"
                    printer.printFormatted("\(.raw("    Tools:   \(result.tool) \(mark)"))")
                }
            }

            if let workDir = task.workingDirectory ?? pipeline.workingDirectory {
                printer.printFormatted("\(.raw("    WorkDir: \(workDir)"))")
            }
            if task.continueOnError == true {
                printer.printFormatted("\(.raw("    Flags:   continue-on-error"))")
            }
            printer.printFormatted("\(.raw(""))")
        }

        printer.printFormatted("\(.info("No tasks executed."))")
    }
}
