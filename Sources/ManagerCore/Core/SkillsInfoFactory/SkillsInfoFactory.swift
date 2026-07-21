//  SkillsInfoFactory.swift

import Foundation
import LucaFoundation

/// Creates ``SkillsInfo`` instances from various installation type descriptions.
struct SkillsInfoFactory {

    /// Errors thrown by ``SkillsInfoFactory``.
    enum SkillsInfoFactoryError: Error, LocalizedError, Equatable {
        /// A version ref is required for individual installs but was not provided.
        case missingVersion(repository: String)
        /// Two skills from the same repository declare different versions.
        case versionConflict(repository: String, existing: String, conflicting: String)

        var errorDescription: String? {
            switch self {
            case .missingVersion(let repository):
                return "No version specified for '\(repository)'. Use --ref to pin to a git tag or commit SHA (e.g. --ref v1.2.0)."
            case .versionConflict(let repository, let existing, let conflicting):
                return "Version conflict for '\(repository)': '\(existing)' and '\(conflicting)' cannot be installed together. Pin all skills from this repository to the same version."
            }
        }
    }

    private let specLoader: SpecLoading

    init(specLoader: SpecLoading) {
        self.specLoader = specLoader
    }
    
    // MARK: - Internal
    
    /// Returns the list of skills to install for the given installation type.
    /// - Parameter installationType: Specifies whether to read from a spec file or install a single skill directly.
    func skillsInfoForInstallationType(_ installationType: SkillInstallationType) async throws -> SkillsInfo {
        switch installationType {
        case .spec(let specPath):
            let spec = try specLoader.loadSpec(at: specPath)
            let skills = spec.skills ?? []

            // Phase 1: separate repos that want all skills (nil name) from repos with named skills.
            // Track the first non-nil version encountered per repo.
            var allSkillsRepos = Set<String>()
            var namedSkillsByRepo = [String: [String]]()
            var versionByRepo = [String: String]()
            for skill in skills {
                if let existing = versionByRepo[skill.repository] {
                    guard existing == skill.version else {
                        throw SkillsInfoFactoryError.versionConflict(
                            repository: skill.repository,
                            existing: existing,
                            conflicting: skill.version
                        )
                    }
                } else {
                    versionByRepo[skill.repository] = skill.version
                }
                if let name = skill.name {
                    namedSkillsByRepo[skill.repository, default: []].append(name)
                } else {
                    allSkillsRepos.insert(skill.repository)
                }
            }

            // Phase 2: merge — "all skills" repos always win over named entries for the same repo.
            // An empty `skills` array in `SkillSet` signals "install all skills from this repo".
            var skillSetsByRepo = [String: [String]]()
            for repo in allSkillsRepos {
                skillSetsByRepo[repo] = []
            }
            for (repo, names) in namedSkillsByRepo where !allSkillsRepos.contains(repo) {
                skillSetsByRepo[repo] = names
            }

            let skillSets: [SkillSet] = skillSetsByRepo.compactMap { repo, names in
                versionByRepo[repo].map { SkillSet(repository: repo, skills: names, version: $0) }
            }
            return SkillsInfo(agents: spec.agents, skillSets: skillSets)

        case .individual(let repository, let skillNames, let agents, let ref):
            guard let ref else {
                throw SkillsInfoFactoryError.missingVersion(repository: repository)
            }
            let skillSet = SkillSet(repository: repository, skills: skillNames, version: ref)
            return SkillsInfo(agents: agents, skillSets: [skillSet])
        }
    }
}
