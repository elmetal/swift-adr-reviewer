// swift-tools-version: 6.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "swift-adr-reviewer",
    platforms: [
        .macOS(.v13),
    ],
    products: [
        .executable(name: "adr-reviewer", targets: ["ADRReviewerCLI"]),
        .library(name: "ADRReviewer", targets: ["ADRReviewer"]),
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-argument-parser.git", from: "1.5.0"),
        .package(url: "https://github.com/swiftlang/swift-markdown.git", from: "0.9.0"),
    ],
    targets: [
        .target(
            name: "ADRReviewer",
            dependencies: [
                .product(name: "Markdown", package: "swift-markdown"),
            ]
        ),
        .executableTarget(
            name: "ADRReviewerCLI",
            dependencies: [
                "ADRReviewer",
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
            ]
        ),
        .testTarget(
            name: "ADRReviewerTests",
            dependencies: ["ADRReviewer"]
        ),
    ],
    swiftLanguageModes: [.v6]
)
