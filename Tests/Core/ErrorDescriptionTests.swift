//  ErrorDescriptionTests.swift

import Foundation
import Testing
@testable import LucaFoundation
@testable import ManagerCore

struct ErrorDescriptionTests {

    @Test
    func binaryFinderError_errorDescription() {
        let path = "/some/path"
        #expect(BinaryFinder.BinaryFinderError.cannotConstructUrl(path: path).errorDescription != nil)
        #expect(BinaryFinder.BinaryFinderError.cannotEnumerateDirectory(path: path).errorDescription != nil)
        #expect(BinaryFinder.BinaryFinderError.missingBinaryFile(location: path).errorDescription != nil)
    }

    @Test
    func checksumCalculatorError_errorDescription() {
        let path = "/some/path"
        #expect(ChecksumCalculator.ChecksumCalculatorError.invalidFile(path: path).errorDescription != nil)
        #expect(ChecksumCalculator.ChecksumCalculatorError.missingFile(path: path).errorDescription != nil)
    }

    @Test
    func checksumValidatorError_errorDescription() {
        let path = "/some/path"
        #expect(ChecksumValidator.ChecksumValidatorError.invalidChecksum(path: path).errorDescription != nil)
    }

    @Test
    func gitHubReleaseURLFactoryError_errorDescription() {
        let release = Release(organization: "org", repository: "repo", version: "1.0.0")
        #expect(GitHubReleaseURLFactory.GitHubReleaseURLFactoryError.cannotConstructUrl(release).errorDescription != nil)
    }

    @Test
    func toolInstallerError_errorDescription() {
        #expect(ToolInstaller.ToolInstallerError.unknownFileType("/some/file").errorDescription != nil)
    }

    @Test
    func skillInstallerError_errorDescription() {
        #expect(SkillInstaller.SkillInstallerError.npxNotAvailable.errorDescription != nil)
        #expect(SkillInstaller.SkillInstallerError.installationFailed("my-skill", 1).errorDescription != nil)
    }


    @Test
    func permissionManagerError_errorDescription() {
        let path = "/some/path"
        #expect(PermissionManager.PermissionManagerError.missingFile(path).errorDescription != nil)
        #expect(PermissionManager.PermissionManagerError.unableToRetrievePosixPermissions(path).errorDescription != nil)
    }

    @Test
    func releaseInfoProviderError_errorDescription() {
        let assets = [ReleaseAsset(name: "tool.zip", url: "https://example.com/tool.zip")]
        let url = URL(string: "https://example.com")!
        #expect(ReleaseInfoProvider.ReleaseInfoProviderError.apiError("error").errorDescription != nil)
        #expect(ReleaseInfoProvider.ReleaseInfoProviderError.cannotIdentifyAsset(assets).errorDescription != nil)
        #expect(ReleaseInfoProvider.ReleaseInfoProviderError.releaseNotFound(url).errorDescription != nil)
    }

    @Test
    func specLoaderError_errorDescription() {
        let path = "/some/path"
        let underlyingError = NSError(domain: "test", code: 1)
        #expect(SpecLoader.SpecLoaderError.missingSpec(path).errorDescription != nil)
        #expect(SpecLoader.SpecLoaderError.invalidSpec(path, underlyingError).errorDescription != nil)
    }

    @Test
    func symLinkerError_errorDescription() {
        #expect(SymLinker.SymLinkerError.missingBinaryFile(binaryName: "tool", expectedLocation: "/some/path").errorDescription != nil)
    }

    @Test
    func toolFactoryError_errorDescription() {
        #expect(ToolFactory.ToolFactoryError.invalidIdentifierFormat("bad-format").errorDescription != nil)
        #expect(ToolFactory.ToolFactoryError.invalidRepositoryFormat("bad-format").errorDescription != nil)
    }

    @Test
    func unarchiverError_errorDescription() {
        let underlyingError = NSError(domain: "test", code: 1)
        #expect(Unarchiver.UnarchiverError.unrecognizedFileType("/some/file").errorDescription != nil)
        #expect(Unarchiver.UnarchiverError.notAnArchive("/some/file").errorDescription != nil)
        #expect(Unarchiver.UnarchiverError.failedToUnarchive(underlyingError).errorDescription != nil)
        #expect(Unarchiver.UnarchiverError.unsafeArchiveEntry("../escape.txt").errorDescription != nil)
    }

    @Test
    func uninstallerError_errorDescription() {
        #expect(Uninstaller.UninstallerError.versionNotFound(tool: "tool", version: "1.0.0").errorDescription != nil)
    }

    @Test
    func unlinkerError_errorDescription() {
        #expect(Unlinker.UnlinkerError.symlinkNotFound(symlink: "tool").errorDescription != nil)
    }

    @Test
    func versionListerError_errorDescription() {
        #expect(VersionLister.VersionListerError.toolNotFound(tool: "tool").errorDescription != nil)
    }

    @Test
    func architectureValidatorError_errorDescription() {
        #expect(ArchitectureValidator.ArchitectureValidatorError.incompatibleArchitecture(
            binary: "tool",
            binaryArch: .arm64,
            hostArch: .x86_64
        ).errorDescription != nil)
        #expect(ArchitectureValidator.ArchitectureValidatorError.unableToReadBinary(path: "/some/path").errorDescription != nil)
        #expect(ArchitectureValidator.ArchitectureValidatorError.unknownArchitecture(path: "/some/path").errorDescription != nil)
    }

    @Test
    func gitHubSkillTreeClientError_errorDescription() {
        #expect(GitHubSkillTreeClientError.invalidURL.errorDescription != nil)
        #expect(GitHubSkillTreeClientError.unexpectedResponse(statusCode: 404).errorDescription != nil)
        #expect(GitHubSkillTreeClientError.decodingFailed.errorDescription != nil)
        #expect(GitHubSkillTreeClientError.treeTruncated.errorDescription != nil)
    }

    @Test
    func skillFrontmatterParserError_errorDescription() {
        #expect(SkillFrontmatterParser.SkillFrontmatterParserError.missingNameField.errorDescription != nil)
        #expect(SkillFrontmatterParser.SkillFrontmatterParserError.invalidFrontmatter.errorDescription != nil)
    }

    @Test
    func skillDownloaderError_errorDescription() {
        #expect(SkillDownloader.SkillDownloaderError.invalidRepository("owner/repo").errorDescription != nil)
        #expect(SkillDownloader.SkillDownloaderError.gitNotFound.errorDescription != nil)
        #expect(SkillDownloader.SkillDownloaderError.cloneFailed(repository: "owner/repo").errorDescription != nil)
        #expect(SkillDownloader.SkillDownloaderError.repositoryNotFound("owner/repo").errorDescription != nil)
        #expect(SkillDownloader.SkillDownloaderError.rateLimitExceeded.errorDescription != nil)
        #expect(SkillDownloader.SkillDownloaderError.noSkillsFound(repository: "owner/repo").errorDescription != nil)
        #expect(SkillDownloader.SkillDownloaderError.skillNotFound(name: "my-skill", repository: "owner/repo").errorDescription != nil)
        #expect(SkillDownloader.SkillDownloaderError.downloadFailed(path: "/some/path").errorDescription != nil)
    }

    @Test
    func skillSymLinkerError_errorDescription() {
        #expect(SkillSymLinker.SkillSymLinkerError.agentDirectoryCreationFailed(path: "/some/path").errorDescription != nil)
        #expect(SkillSymLinker.SkillSymLinkerError.symLinkCreationFailed(from: "/source", to: "/dest").errorDescription != nil)
    }

    @Test
    func skillUninstallerError_errorDescription() {
        #expect(SkillUninstaller.SkillUninstallerError.skillNotFound(name: "my-skill").errorDescription != nil)
    }

    @Test
    func installerError_errorDescription() {
        #expect(Installer.InstallerError.runningFromHomeDirectory.errorDescription != nil)
        #expect(Installer.InstallerError.unsafeSkillPath("../../escaped.txt").errorDescription != nil)
    }

    @Test
    func skillDecodingError_errorDescription() {
        #expect(Skill.SkillDecodingError.missingVersion(repository: "owner/repo").errorDescription != nil)
    }

    @Test
    func skillsInfoFactoryError_errorDescription() {
        #expect(SkillsInfoFactory.SkillsInfoFactoryError.missingVersion(repository: "owner/repo").errorDescription != nil)
        #expect(SkillsInfoFactory.SkillsInfoFactoryError.versionConflict(repository: "owner/repo", existing: "v1.0.0", conflicting: "v2.0.0").errorDescription != nil)
    }

    @Test
    func gitRepositorySkillFetcherError_errorDescription() {
        #expect(GitRepositorySkillFetcherError.gitNotFound.errorDescription != nil)
        #expect(GitRepositorySkillFetcherError.cloneFailed(repository: "owner/repo", exitCode: 128).errorDescription != nil)
        #expect(GitRepositorySkillFetcherError.checkoutFailed(repository: "owner/repo", ref: "abc1234", exitCode: 128).errorDescription != nil)
        #expect(GitRepositorySkillFetcherError.fileReadFailed(path: "/some/path").errorDescription != nil)
    }
}
