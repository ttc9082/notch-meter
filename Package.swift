// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "NotchCodex",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(name: "notch-codex", targets: ["NotchCodex"]),
        .executable(name: "usage-fixture-check", targets: ["UsageFixtureCheck"]),
        .library(name: "CodexUsageCore", targets: ["CodexUsageCore"])
    ],
    targets: [
        .target(name: "CodexUsageCore"),
        .executableTarget(
            name: "NotchCodex",
            dependencies: ["CodexUsageCore"]
        ),
        .executableTarget(
            name: "UsageFixtureCheck",
            dependencies: ["CodexUsageCore"]
        )
    ]
)
