//  QuietPrinter.swift

import Foundation
import Noora

/// A no-op ``Printing`` implementation that discards all output.
///
/// Use ``QuietPrinter`` when output should be suppressed, for example
/// during quiet-mode installs driven by Noora progress steps.
public struct QuietPrinter: Printing {

    public init() {}

    public func printFormatted(_ terminalText: TerminalText) {}
}
