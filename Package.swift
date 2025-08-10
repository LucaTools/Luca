// swift-tools-version: 5.7
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Luca",
    platforms: [.macOS(.v13)],
    products: [
        .executable(name: "luca", targets: ["LucaCLI"]),
        .library(name: "LucaCore", targets: ["LucaCore"])
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-argument-parser", from: "1.1.2"),
        .package(url: "https://github.com/jpsim/Yams.git", from: "5.0.6")
    ],
    targets: [
        .executableTarget(
            name: "LucaCLI",
            dependencies: [
                .target(name: "LucaCore"),
                .product(name: "ArgumentParser", package: "swift-argument-parser")
            ],
            path: "Sources/LucaCLI"
        ),
        .target(
            name: "LucaCore",
            dependencies: [
                .product(name: "Yams", package: "Yams")
            ],
            path: "Sources/LucaCore"
        ),
        .testTarget(
            name: "LucaTests",
            dependencies: [
                .target(name: "LucaCore"),
            ],
            path: "Tests"
        )
    ]
)
