//  SkillsInfoFactory.swift

import Foundation
import LucaFoundation

/// Creates ``SkillsInfo`` instances from various installation type descriptions.
struct SkillsInfoFactory {

    /// Errors thrown by ``SkillsInfoFactory``.
    enum SkillsInfoFactoryError: Error, LocalizedError, Equatable {
        /// A version ref is required for individual installs but was not provided.
        case missingVersion(repository: String)

        var errorDescription: String? {
            switch self {
            case .missingVersion(let repository):
                return "No version specified for '\(repository)'. Use --ref to pin to a git tag or commit SHA (e.g. --ref v1.2.0)."
            }
        }
    }

    /// Groups skills by their (repository URL, version) pair so that the same URL at different
    /// SHAs produces separate ``SkillSet``s — each checked out independently.
    private struct SkillGroupKey: Hashable {
        let repository: String
        let version: String
    }

    private let specLoader: SpecLoading
    private let skillVersionResolver: SkillLatestVersionResolving

    init(specLoader: SpecLoading, skillVersionResolver: SkillLatestVersionResolving = SkillLatestVersionResolver()) {
        self.specLoader = specLoader
        self.skillVersionResolver = skillVersionResolver
    }
    
    // MARK: - Internal
    
    /// Returns the list of skills to install for the given installation type.
    /// - Parameter installationType: Specifies whether to read from a spec file or install a single skill directly.
    func skillsInfoForInstallationType(_ installationType: SkillInstallationType) async throws -> SkillsInfo {
        switch installationType {
        case .spec(let specPath):
            let spec = try specLoader.loadSpec(at: specPath)
            let skills = try await resolveLatestVersions(in: spec.skills ?? [])

            // Phase 1: separate groups that want all skills (nil name) from those with named skills.
            // Skills are grouped by (repository, version) so the same URL at different SHAs
            // produces independent SkillSets — each checked out separately.
            var allSkillsGroups = Set<SkillGroupKey>()
            var namedSkillsByGroup = [SkillGroupKey: [String]]()
            for skill in skills {
                let key = SkillGroupKey(repository: skill.repository, version: skill.version)
                if let name = skill.name {
                    namedSkillsByGroup[key, default: []].append(name)
                } else {
                    allSkillsGroups.insert(key)
                }
            }

            // Phase 2: merge — "all skills" groups always win over named entries for the same key.
            // An empty `skills` array in `SkillSet` signals "install all skills from this repo".
            var skillSetsByGroup = [SkillGroupKey: [String]]()
            for key in allSkillsGroups {
                skillSetsByGroup[key] = []
            }
            for (key, names) in namedSkillsByGroup where !allSkillsGroups.contains(key) {
                skillSetsByGroup[key] = names
            }

            let skillSets = skillSetsByGroup.map { key, names in
                SkillSet(repository: key.repository, skills: names, version: key.version)
            }
            return SkillsInfo(agents: spec.agents, skillSets: skillSets)

        case .individual(let repository, let skillNames, let agents, let ref):
            guard let ref else {
                throw SkillsInfoFactoryError.missingVersion(repository: repository)
            }
            let resolvedRef = ref == Skill.latestVersionKeyword
                ? try await skillVersionResolver.resolveLatestVersion(repository: repository)
                : ref
            let skillSet = SkillSet(repository: repository, skills: skillNames, version: resolvedRef)
            return SkillsInfo(agents: agents, skillSets: [skillSet])
        }
    }

    // MARK: - Private

    /// Replaces every `Skill.latestVersionKeyword` version with a concrete commit SHA.
    ///
    /// Resolves at most once per distinct repository — multiple skill entries requesting
    /// `latest` for the same repository must land on the same resolved SHA so they merge
    /// into a single ``SkillSet`` in the grouping phase.
    private func resolveLatestVersions(in skills: [Skill]) async throws -> [Skill] {
        var resolvedByRepository: [String: String] = [:]
        var result: [Skill] = []
        for skill in skills {
            guard skill.version == Skill.latestVersionKeyword else {
                result.append(skill)
                continue
            }
            let resolved: String
            if let cached = resolvedByRepository[skill.repository] {
                resolved = cached
            } else {
                resolved = try await skillVersionResolver.resolveLatestVersion(repository: skill.repository)
                resolvedByRepository[skill.repository] = resolved
            }
            result.append(Skill(name: skill.name, repository: skill.repository, version: resolved))
        }
        return result
    }
}
