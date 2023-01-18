// swift-tools-version:5.1
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "HttpManInTheMiddle",
    dependencies: [
        .package(url: "https://github.com/tomieq/swifter.git", .exact("1.5.6"))
    ],
    targets: [
        .target(
            name: "HttpManInTheMiddle",
            dependencies: ["Swifter"],
            path: "Sources")
    ]
)
