// swift-tools-version:5.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Settler",
    products: [
        .executable(name: "settler", targets: ["SettlerCLI"]),
        .library(name: "SettlerFramework", targets: ["SettlerFramework"]),
        .library(name: "Settler", targets: ["Settler"]),
        .executable(name: "SettlerDemo", targets: ["SettlerDemo"]),
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-argument-parser", from: "0.2.1"),
        .package(url: "https://github.com/jpsim/SourceKitten.git", from: "0.29.0"),
    ],
    targets: [
        .target(name: "SettlerCLI", dependencies: [
            .product(name: "ArgumentParser", package: "swift-argument-parser"),
            "SettlerFramework",
        ]),
        .target(name: "SettlerFramework", dependencies: [
            .product(name: "SourceKittenFramework", package: "SourceKitten"),
        ]),
        .testTarget(name: "SettlerTests", dependencies: ["SettlerFramework"]),
        .target(name: "Settler", dependencies: []),
        .target(name: "SettlerDemo", dependencies: ["Settler"]),
    ]
)
