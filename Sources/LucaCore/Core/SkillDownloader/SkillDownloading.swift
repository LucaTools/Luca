//  SkillDownloading.swift

import Foundation

/// Downloads skill files from a remote repository.
protocol SkillDownloading {
    /// Downloads the content of all matching skills from the given skill set's repository.
    ///
    /// - Parameter skillSet: The ``SkillSet`` describing the repository and optional skill filter.
    /// - Returns: An array of `(name, files)` tuples. Each `files` array contains every file
    ///   in that skill's directory, with paths expressed relative to the skill root.
    func download(skillSet: SkillSet) async throws -> [(name: String, files: [SkillFile])]
}
