// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Luca",
    platforms: [.macOS(.v13)],
    products: [
        .executable(name: "luca", targets: ["LucaCLI"]),
        .library(name: "LucaCore", targets: ["LucaCore"]),
        .library(name: "LucaFoundation", targets: ["LucaFoundation"]),
        .library(name: "PipelineCore", targets: ["PipelineCore"]),
        .library(name: "ManagerCore", targets: ["ManagerCore"])
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-argument-parser", exact: "1.7.1"),
        .package(url: "https://github.com/apple/swift-crypto.git", exact: "4.0.0"),
        .package(url: "https://github.com/tuist/Noora", exact: "0.56.0"),
        .package(url: "https://github.com/jpsim/Yams.git", exact: "6.1.0"),
        .package(url: "https://github.com/swiftlang/swift-docc-plugin", from: "1.1.0")
    ],
    targets: [
        .executableTarget(
            name: "LucaCLI",
            dependencies: [
                .target(name: "LucaCore"),
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
                .product(name: "Noora", package: "Noora"),
                .product(name: "Yams", package: "Yams")
            ],
            path: "Sources/LucaCLI"
        ),
        .target(
            name: "LucaCore",
            dependencies: [
                .target(name: "LucaFoundation"),
                .target(name: "PipelineCore"),
                .target(name: "ManagerCore")
            ],
            path: "Sources/LucaCore"
        ),
        .target(
            name: "LucaFoundation",
            dependencies: [
                .product(name: "Noora", package: "Noora"),
                .product(name: "Yams", package: "Yams")
            ],
            path: "Sources/LucaFoundation"
        ),
        .target(
            name: "PipelineCore",
            dependencies: [
                .target(name: "LucaFoundation"),
                .product(name: "Noora", package: "Noora"),
                .product(name: "Yams", package: "Yams")
            ],
            path: "Sources/PipelineCore"
        ),
        .target(
            name: "ManagerCore",
            dependencies: [
                .target(name: "LucaFoundation"),
                .product(name: "Crypto", package: "swift-crypto"),
                .product(name: "Noora", package: "Noora"),
                .product(name: "Yams", package: "Yams")
            ],
            path: "Sources/ManagerCore"
        ),
        .testTarget(
            name: "LucaTests",
            dependencies: [
                .target(name: "LucaCore"),
                .target(name: "PipelineCore"),
                .target(name: "ManagerCore")
            ],
            path: "Tests",
            resources: [
                .process("Fixtures")
            ]
        )
    ]
)
