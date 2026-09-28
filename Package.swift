// swift-tools-version: 6.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "swift-adr-reviewer",
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "swift-adr-reviewer",
            targets: ["swift-adr-reviewer"]
        ),
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .target(
            name: "swift-adr-reviewer"
        ),
        .testTarget(
            name: "swift-adr-reviewerTests",
            dependencies: ["swift-adr-reviewer"]
        ),
    ],
    swiftLanguageModes: [.v6]
)
