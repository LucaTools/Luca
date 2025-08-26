//  MyFileManager.swift

import Foundation

class MyFileManager: FileManager {

    override var homeDirectoryForCurrentUser: URL {
        temporaryDirectory.appending(component: "home")
    }

    override var currentDirectoryPath: String {
        temporaryDirectory.appending(component: "project").absoluteString
    }
}
