//  Unarchiving.swift

import Foundation

protocol Unarchiving {
    func unarchive(filePath: URL, installationDestination: URL) throws
}
