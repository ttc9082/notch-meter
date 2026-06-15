// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "NotchMeter",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(name: "notch-meter", targets: ["NotchMeter"]),
        .executable(name: "usage-fixture-check", targets: ["UsageFixtureCheck"]),
        .library(name: "AgentUsageCore", targets: ["AgentUsageCore"])
    ],
    targets: [
        .target(name: "AgentUsageCore"),
        .executableTarget(
            name: "NotchMeter",
            dependencies: ["AgentUsageCore"],
            resources: [
                .process("Resources")
            ]
        ),
        .executableTarget(
            name: "UsageFixtureCheck",
            dependencies: ["AgentUsageCore"]
        )
    ]
)
