//  NooraMock.swift

import Noora
import Foundation

struct NooraMock: Noorable {
    func passthrough(_ text: TerminalText, pipeline: StandardPipelineType) {}
    func success(_ alert: SuccessAlert) {}
    func error(_ alert: ErrorAlert) {}
    func warning(_ alerts: WarningAlert...) {}
    func warning(_ alerts: [WarningAlert]) {}
    func info(_ alert: InfoAlert) {}
    func format(_ terminalText: TerminalText) -> String { return "" }
    
    func progressStep<V>(
        message: String,
        successMessage: String?,
        errorMessage: String?,
        showSpinner: Bool,
        renderer: any Rendering,
        task: @escaping ((String) -> Void) async throws -> V
    ) async throws -> V {
        return try await task { _ in }
    }

    func collapsibleStep(
        title: TerminalText,
        successMessage: TerminalText?,
        errorMessage: TerminalText?,
        visibleLines: UInt,
        renderer: any Rendering,
        task: @escaping (@escaping (TerminalText) -> Void) async throws -> Void
    ) async throws -> Void {
        try await task { _ in }
    }

    func progressBarStep<V>(
        message: String,
        successMessage: String?,
        errorMessage: String?,
        renderer: any Rendering,
        task: @escaping (@escaping (Double) -> Void) async throws -> V
    ) async throws -> V {
        return try await task { _ in }
    }

    func json(_ item: some Codable, encoder: JSONEncoder) throws {}
}
