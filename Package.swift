

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
            path: "https://github.com/nbsfuse/fuse-ios/releases/download/0.2.15/NBSFuse.xcframework.zip",
            checksum: "a018ec6a1be53401cca4db180b5622d5f11704f1"
        )
    ]
)
