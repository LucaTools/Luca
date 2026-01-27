//  Header.swift

import Foundation
import LucaCore

struct Header {

    let printer: Printing

    func printHeader() {
        let asciiHeader = """
        
        ██╗     ██╗   ██╗ ██████╗ █████╗ 
        ██║     ██║   ██║██╔════╝██╔══██╗
        ██║     ██║   ██║██║     ███████║
        ██║     ██║   ██║██║     ██╔══██║
        ███████╗╚██████╔╝╚██████╗██║  ██║
        ╚══════╝ ╚═════╝  ╚═════╝╚═╝  ╚═╝
        """
        
        let headerWidth = 33
        let versionText = "version \(version)"
        let paddedVersion = String(repeating: " ", count: max(0, headerWidth - versionText.count)) + versionText
        
        let fullHeader = asciiHeader + "\n" + paddedVersion
        
        printer.printFormatted("\(.accent(fullHeader))")
    }
}
