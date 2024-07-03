// swift-tools-version:5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "HttpManInTheMiddle",
    dependencies: [
        .package(url: "https://github.com/tomieq/swifter.git", branch: "develop")
    ],
    targets: [
        .executableTarget(
            name: "HttpManInTheMiddle",
            dependencies: [
                .product(name: "Swifter", package: "Swifter")
            ],
            path: "Sources")
    ]
)
