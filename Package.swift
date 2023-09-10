// swift-tools-version:5.8

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
            path: "https://github.com/nbsfuse/fuse-ios/releases/download/0.2.16/NBSFuse.xcframework.zip",
            checksum: "08c851e1ae26244364d464bce116a7f02822323c"
        )
    ]
)
