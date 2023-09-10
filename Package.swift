// swift-tools-version: 5.8

import PackageDescription

let package = Package(
    name: "NBSFuse",
    platforms: [ .iOS("13.0") ],
    products: [
        .library(
            name: "NBSFuse",
            targets: ["NBSFuse"]
        )
    ],
    dependencies: [],
    targets: [
        .binaryTarget(
            name: "NBSFuse",
            path: "https://github.com/nbsfuse/fuse-ios/releases/download/0.2.17/NBSFuse.xcframework.zip",
            checksum: "e8e99327af9583780c8588898308b4ec1b4271e1"
        )
    ]
)
