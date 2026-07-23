//  GitHubTokenResolverTests.swift

import Testing
@testable import ManagerCore

struct GitHubTokenResolverTests {

    @Test
    func test_token_forGitHubDotCom_readsPlainVariable() {
        let sut = GitHubTokenResolver(environment: ["LUCA_GITHUB_TOKEN": "dotcom-token"])
        #expect(sut.token(forHost: "github.com") == "dotcom-token")
    }

    @Test
    func test_token_forEnterpriseHost_readsSanitizedVariable() {
        let sut = GitHubTokenResolver(environment: ["LUCA_GITHUB_TOKEN_GHE_MY_COMPANY_COM": "ghe-token"])
        #expect(sut.token(forHost: "ghe.my-company.com") == "ghe-token")
    }

    @Test
    func test_token_missingVariable_returnsNil() {
        let sut = GitHubTokenResolver(environment: [:])
        #expect(sut.token(forHost: "github.com") == nil)
        #expect(sut.token(forHost: "ghe.my-company.com") == nil)
    }

    @Test
    func test_token_emptyVariable_returnsNil() {
        let sut = GitHubTokenResolver(environment: ["LUCA_GITHUB_TOKEN": ""])
        #expect(sut.token(forHost: "github.com") == nil)
    }

    @Test
    func test_token_hostWithPort_sanitizesColonAndDigits() {
        let sut = GitHubTokenResolver(environment: ["LUCA_GITHUB_TOKEN_GHE_INTERNAL_COM_8443": "port-token"])
        #expect(sut.token(forHost: "ghe.internal.com:8443") == "port-token")
    }
}
