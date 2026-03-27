//  Printer.swift

import Foundation
import Noora

/// The standard ``Printing`` implementation that outputs to stdout using Noora formatting.
public struct Printer: Printing {

    private let noora: Noorable

    public init(noora: Noorable) {
        self.noora = noora
    }

    /// Formats and prints the terminal text to stdout.
    public func printFormatted(_ terminalText: TerminalText) {
        print(noora.format(terminalText))
    }
}
