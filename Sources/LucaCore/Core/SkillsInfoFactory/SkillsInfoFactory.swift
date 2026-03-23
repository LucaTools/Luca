//  SkillsInfoFactory.swift

import Foundation

/// Creates ``SkillsInfo`` instances from various installation type descriptions.
struct SkillsInfoFactory {

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
            var allSkillsRepos = Set<String>()
            var namedSkillsByRepo = [String: [String]]()
            for skill in skills {
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

            let skillSets = skillSetsByRepo.map { SkillSet(repository: $0.key, skills: $0.value) }
            return SkillsInfo(
                agents: spec.agents,
                skillSets: skillSets
            )
        }
    }
}
