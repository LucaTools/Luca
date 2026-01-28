//  Spec.swift

import Foundation

/// A specification defining the tools required for a project.
///
/// A `Spec` represents the parsed contents of a Lucafile. It contains
/// an array of ``Tool`` definitions that Luca will install and manage.
///
/// ## Lucafile Example
///
/// ```yaml
/// ---
/// tools:
///   - name: SwiftLint
///     version: 0.61.0
///     url: https://github.com/realm/SwiftLint/releases/...
///   - name: Tuist
///     version: 4.80.0
///     url: https://github.com/tuist/tuist/releases/...
/// ```
///
/// ## Topics
///
/// ### Properties
/// - ``tools``
///
/// ### Related Types
/// - ``Tool``
/// - ``SpecLoader``
struct Spec: Codable {
    /// The list of tools defined in the specification.
    let tools: [Tool]
}
