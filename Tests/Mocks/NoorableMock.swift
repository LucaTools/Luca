//  NoorableMock.swift

import Foundation
import Noora
@testable import LucaCore

class NoorableMock: Noorable {

    private(set) var formatCallCount = 0
    private(set) var lastFormattedText: TerminalText?

    func format(_ terminalText: TerminalText) -> String {
        formatCallCount += 1
        lastFormattedText = terminalText
        return ""
    }

    func passthrough(_ text: TerminalText, pipeline: StandardPipelineType) {}

    func singleChoicePrompt<T: Equatable & CustomStringConvertible>(
        title: TerminalText?,
        question: TerminalText,
        options: [T],
        description: TerminalText?,
        collapseOnSelection: Bool,
        filterMode: SingleChoicePromptFilterMode,
        autoselectSingleChoice: Bool,
        renderer: Rendering
    ) -> T {
        fatalError("Not implemented in mock")
    }

    func singleChoicePrompt<T: CaseIterable & CustomStringConvertible & Equatable>(
        title: TerminalText?,
        question: TerminalText,
        description: TerminalText?,
        collapseOnSelection: Bool,
        filterMode: SingleChoicePromptFilterMode,
        autoselectSingleChoice: Bool,
        renderer: Rendering
    ) -> T {
        fatalError("Not implemented in mock")
    }

    func multipleChoicePrompt<T: Equatable & CustomStringConvertible>(
        title: TerminalText?,
        question: TerminalText,
        options: [T],
        description: TerminalText?,
        collapseOnSelection: Bool,
        filterMode: MultipleChoicePromptFilterMode,
        maxLimit: MultipleChoiceLimit,
        minLimit: MultipleChoiceLimit,
        renderer: Rendering
    ) -> [T] {
        fatalError("Not implemented in mock")
    }

    func multipleChoicePrompt<T: CaseIterable & CustomStringConvertible & Equatable>(
        title: TerminalText?,
        question: TerminalText,
        description: TerminalText?,
        collapseOnSelection: Bool,
        filterMode: MultipleChoicePromptFilterMode,
        maxLimit: MultipleChoiceLimit,
        minLimit: MultipleChoiceLimit,
        renderer: Rendering
    ) -> [T] {
        fatalError("Not implemented in mock")
    }

    func yesOrNoChoicePrompt(
        title: TerminalText?,
        question: TerminalText,
        defaultAnswer: Bool,
        description: TerminalText?,
        collapseOnSelection: Bool,
        renderer: Rendering
    ) -> Bool {
        fatalError("Not implemented in mock")
    }

    func textPrompt(
        title: TerminalText?,
        prompt: TerminalText,
        description: TerminalText?,
        collapseOnAnswer: Bool,
        renderer: Rendering,
        validationRules: [ValidatableRule]
    ) -> String {
        fatalError("Not implemented in mock")
    }

    func success(_ alert: SuccessAlert) {}
    func error(_ alert: ErrorAlert) {}
    func warning(_ alerts: WarningAlert...) {}
    func warning(_ alerts: [WarningAlert]) {}
    func info(_ alert: InfoAlert) {}

    func progressStep<V>(
        message: String,
        successMessage: String?,
        errorMessage: String?,
        showSpinner: Bool,
        renderer: Rendering,
        task: @escaping ((String) -> Void) async throws -> V
    ) async throws -> V {
        fatalError("Not implemented in mock")
    }

    func collapsibleStep(
        title: TerminalText,
        successMessage: TerminalText?,
        errorMessage: TerminalText?,
        visibleLines: UInt,
        renderer: Rendering,
        task: @escaping (@escaping (TerminalText) -> Void) async throws -> Void
    ) async throws {}

    func progressBarStep<V>(
        message: String,
        successMessage: String?,
        errorMessage: String?,
        renderer: Rendering,
        task: @escaping (@escaping (Double) -> Void) async throws -> V
    ) async throws -> V {
        fatalError("Not implemented in mock")
    }

    func table(headers: [String], rows: [[String]], renderer: Rendering) {}
    func table(_ data: TableData, renderer: Rendering) {}
    func table(headers: [TableCellStyle], rows: [StyledTableRow], renderer: Rendering) {}

    func selectableTable(
        headers: [String],
        rows: [[String]],
        pageSize: Int,
        renderer: Rendering
    ) async throws -> Int {
        fatalError("Not implemented in mock")
    }

    func selectableTable(
        _ data: TableData,
        pageSize: Int,
        renderer: Rendering
    ) async throws -> Int {
        fatalError("Not implemented in mock")
    }

    func selectableTable(
        headers: [TableCellStyle],
        rows: [StyledTableRow],
        pageSize: Int,
        renderer: Rendering
    ) async throws -> Int {
        fatalError("Not implemented in mock")
    }

    func paginatedTable(headers: [String], rows: [[String]], pageSize: Int, renderer: Rendering) throws {}
    func paginatedTable(_ data: TableData, pageSize: Int, renderer: Rendering) throws {}
    func paginatedTable(headers: [TableCellStyle], rows: [StyledTableRow], pageSize: Int, renderer: Rendering) throws {}

    func json(_ item: some Codable, encoder: JSONEncoder) throws {}
}
