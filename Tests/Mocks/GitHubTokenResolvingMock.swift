//  GitHubTokenResolvingMock.swift

import Foundation
@testable import ManagerCore

struct GitHubTokenResolvingMock: GitHubTokenResolving {
    var tokensByHost: [String: String] = [:]

    func token(forHost host: String) -> String? {
        tokensByHost[host]
    }
}
