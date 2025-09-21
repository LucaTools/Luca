//  Header.swift

import Foundation
import Noora

struct Header {

    let noora: Noorable

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
        
        print(noora.format("\(.accent(fullHeader))"))
    }
}
