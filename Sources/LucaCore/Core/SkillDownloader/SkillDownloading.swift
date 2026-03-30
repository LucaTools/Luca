//  SkillDownloading.swift

import Foundation

/// Downloads skill files from a remote repository.
protocol SkillDownloading {
    /// Downloads the content of all matching skills from the given skill set's repository.
    ///
    /// - Parameter skillSet: The ``SkillSet`` describing the repository and optional skill filter.
    /// - Returns: An array of `(name, content)` tuples for each downloaded skill.
    func download(skillSet: SkillSet) async throws -> [(name: String, content: Data)]
}
