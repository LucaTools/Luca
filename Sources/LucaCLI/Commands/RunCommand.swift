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

    @Option(name: .customLong("param"), help: ArgumentHelp(
        "Set a pipeline parameter value.",
        discussion: """
        Provide KEY=VALUE pairs to satisfy parameters declared in the pipeline's `parameters:` block.
        May be repeated for multiple parameters.
        Example: --param flavor=release --param upload=true
        """,
        valueName: "KEY=VALUE"
    ))
    var params: [String] = []

    /// Path to a YAML file of environment variables injected into every task.
    @Option(name: .customLong("env-file"), help: ArgumentHelp(
        "Path to a YAML file of environment variables injected into every task.",
        discussion: "Defaults to luca-env-vars.yml in the current directory if present. An explicit path fails if the file does not exist.",
        valueName: "path"
    ))
    var envFile: String?

    func validate() throws {
        guard name != nil || file != nil else {
            throw ValidationError("Missing required argument. Provide <name> or --file <path>.")
        }
        if name != nil && file != nil {
            throw ValidationError("<name> and --file are mutually exclusive.")
        }
        for param in params {
            let parts = param.split(separator: "=", maxSplits: 1)
            guard parts.count == 2, !parts[0].isEmpty else {
                throw ValidationError("Invalid --param '\(param)': expected KEY=VALUE format.")
            }
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
        let resolver = ParameterResolver()
        let resolvedParams = try resolver.resolve(
            declared: pipeline.parameters ?? [],
            provided: parsedParams()
        )

        let envFilePath = envFile.map { URL(fileURLWithPath: $0) }
            ?? invocationDirectory.appending(component: "luca-env-vars.yml")
        let isExplicit = envFile != nil
        let envFileLoader = EnvFileLoader(fileManager: fileManager)
        let envFileEnvironment: [String: String]
        do {
            envFileEnvironment = try envFileLoader.load(from: envFilePath)
        } catch EnvFileLoader.EnvFileLoaderError.fileNotFound {
            if isExplicit {
                throw EnvFileLoader.EnvFileLoaderError.fileNotFound(envFilePath)
            }
            envFileEnvironment = [:]
        }

        if dryRun {
            let conditionEvaluator = TaskConditionEvaluator()
            printDryRun(pipeline: pipeline, pipelinePath: pipelinePath, validator: validator,
                        printer: printer, resolvedParams: resolvedParams, providedParams: parsedParams(),
                        conditionEvaluator: conditionEvaluator, envFilePath: envFilePath,
                        envFileEnvironment: envFileEnvironment)
            return
        }

        try validator.validate(pipeline)

        let runner: any PipelineRunning = PipelineRunner(printer: printer)
        try await runner.run(pipeline, currentDirectoryURL: invocationDirectory, parameters: resolvedParams, envFileEnvironment: envFileEnvironment)

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

    private func parsedParams() -> [String: String] {
        params.reduce(into: [:]) { dict, entry in
            let parts = entry.split(separator: "=", maxSplits: 1)
            guard parts.count == 2 else { return }
            dict[String(parts[0])] = String(parts[1])
        }
    }

    private func printDryRun(
        pipeline: Pipeline,
        pipelinePath: URL,
        validator: PipelineValidating,
        printer: Printing,
        resolvedParams: [String: String],
        providedParams: [String: String],
        conditionEvaluator: TaskConditionEvaluating,
        envFilePath: URL,
        envFileEnvironment: [String: String]
    ) {
        let displayName = name ?? pipelinePath.lastPathComponent
        printer.printFormatted("\(.accent("[DRY RUN] Pipeline: \(displayName)"))")
        printer.printFormatted("\(.raw(""))")

        if let declared = pipeline.parameters, !declared.isEmpty {
            printer.printFormatted("\(.primary("Parameters:"))")
            for param in declared {
                let value = resolvedParams[param.name] ?? "(not set)"
                let source: String
                if providedParams.keys.contains(param.name) {
                    source = " (override)"
                } else if param.defaultValue != nil {
                    source = " (default)"
                } else {
                    source = ""
                }
                printer.printFormatted("\(.raw("  \(param.name) = \(value)\(source)"))")
                if let desc = param.description {
                    printer.printFormatted("\(.muted("    \(desc)"))")
                }
            }
            printer.printFormatted("\(.raw(""))")
        }

        if !envFileEnvironment.isEmpty {
            printer.printFormatted("\(.primary("Env file: \(envFilePath.path)"))")
            for key in envFileEnvironment.keys.sorted() {
                printer.printFormatted("\(.raw("  \(key)"))")
            }
            printer.printFormatted("\(.raw(""))")
        }

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

            if let condition = task.when {
                var context: [String: String] = envFileEnvironment
                if let pipelineEnv = pipeline.env { context.merge(pipelineEnv) { _, new in new } }
                if let taskEnv = task.env { context.merge(taskEnv) { _, new in new } }
                context.merge(resolvedParams) { _, new in new }
                let outcome = conditionEvaluator.evaluate(condition: condition, context: context) ? "run" : "skip"
                printer.printFormatted("\(.raw("    When:    \(condition) → \(outcome)"))")
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
