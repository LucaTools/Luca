//  PrinterTests.swift

import Foundation
import Noora
import Testing
@testable import LucaFoundation

struct PrinterTests {

    @Test
    func test_quietPrinter_printFormatted_noops() {
        let sut = QuietPrinter()

        sut.printFormatted("message")
    }

    @Test
    func test_printer_printFormatted_callsNoora() {
        let noora = NoorableMock()
        let sut = Printer(noora: noora)

        sut.printFormatted("message")

        #expect(noora.formatCallCount == 1)
    }
}
