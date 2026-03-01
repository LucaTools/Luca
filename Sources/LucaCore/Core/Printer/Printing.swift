//  Printing.swift

import Foundation
import Noora

/// Formats and outputs terminal messages.
public protocol Printing {

    /// Prints a formatted terminal message.
    /// - Parameter terminalText: The styled text to output.
    func printFormatted(_ terminalText: TerminalText)
}
