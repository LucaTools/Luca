//  Spec.swift

import Foundation

/// Root object decoded from the YAML spec file listing all desired tools.
public struct Spec: Decodable {
    /// The ordered list of tools to ensure are installed.
    let tools: [Tool]
}
