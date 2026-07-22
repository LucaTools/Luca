//  GitRepositoryURLNormalizerTests.swift

import Testing
@testable import ManagerCore

struct GitRepositoryURLNormalizerTests {

    @Test
    func test_cloneURL_shorthand_expandsToGitHubHTTPSURL() {
        #expect(GitRepositoryURLNormalizer.cloneURL(for: "owner/repo") == "https://github.com/owner/repo")
    }

    @Test
    func test_cloneURL_httpsURL_passesThroughUnchanged() {
        #expect(GitRepositoryURLNormalizer.cloneURL(for: "https://github.com/owner/repo.git") == "https://github.com/owner/repo.git")
    }

    @Test
    func test_cloneURL_httpURL_passesThroughUnchanged() {
        #expect(GitRepositoryURLNormalizer.cloneURL(for: "http://internal-git/owner/repo") == "http://internal-git/owner/repo")
    }

    @Test
    func test_cloneURL_sshURL_passesThroughUnchanged() {
        #expect(GitRepositoryURLNormalizer.cloneURL(for: "git@github.com:owner/repo.git") == "git@github.com:owner/repo.git")
    }
}
