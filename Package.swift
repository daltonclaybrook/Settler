// swift-tools-version:5.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Settler",
    products: [
        .executable(name: "settler", targets: ["Settler"]),
        .executable(name: "SettlerDemo", targets: ["SettlerDemo"]),
        .library(name: "SettlerKit", targets: ["SettlerKit"]),
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-argument-parser", from: "0.2.0"),
        .package(url: "https://github.com/jpsim/SourceKitten.git", from: "0.29.0"),
    ],
    targets: [
        .target(name: "Settler", dependencies: [
            .product(name: "ArgumentParser", package: "swift-argument-parser"),
            "SettlerKit",
        ]),
        .target(name: "SettlerDemo", dependencies: [
            "SettlerKit",
        ]),
        .target(name: "SettlerKit", dependencies: [
            .product(name: "SourceKittenFramework", package: "SourceKitten"),
        ]),
        .testTarget(name: "SettlerKitTests", dependencies: ["SettlerKit"]),
    ]
)
