//  Printer.swift

import Foundation
import Noora

public struct Printer: Printing {
    
    private let noora: Noorable
    
    public init(noora: Noorable = Noora()) {
        self.noora = noora
    }
    
    public func printFormatted(_ terminalText: TerminalText) {
        print(noora.format(terminalText))
    }
}
