//  ErrorDescriptionTests.swift

import Foundation
import Testing
@testable import LucaCore

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
    func downloaderError_errorDescription() {
        let url = URL(string: "https://example.com/tool.dmg")!
        #expect(Downloader.DownloaderError.unsupportedFileType(url).errorDescription != nil)
    }

    @Test
    func installerError_errorDescription() {
        #expect(Installer.InstallerError.unknownFileType("/some/file").errorDescription != nil)
        #expect(Installer.InstallerError.skillsRequireSpecInstallationType.errorDescription != nil)
    }

    @Test
    func skillInstallerError_errorDescription() {
        #expect(SkillInstaller.SkillInstallerError.npxNotAvailable.errorDescription != nil)
        #expect(SkillInstaller.SkillInstallerError.installationFailed("my-skill", 1).errorDescription != nil)
    }

    @Test
    func skillRepositoryResolverError_errorDescription() {
        #expect(SkillRepositoryResolver.SkillRepositoryResolverError.invalidRepositoryFormat("bad").errorDescription != nil)
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
}
