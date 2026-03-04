// swift-tools-version: 6.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "RecordingSignalWave",
    platforms: [
        .iOS(.v16),
        .macOS(.v13),
        .tvOS(.v16),
        .watchOS(.v9),
    ],
    products: [
        .library(
            name: "RecordingSignalWave",
            targets: ["RecordingSignalWave"]
        ),
    ],
    targets: [
        .target(
            name: "RecordingSignalWave"
        ),
        .testTarget(
            name: "RecordingSignalWaveTests",
            dependencies: ["RecordingSignalWave"]
        ),
    ]
)
