//  SpecLoading.swift

import Foundation

protocol SpecLoading {
    func loadSpec(at path: URL) throws -> Spec
}
