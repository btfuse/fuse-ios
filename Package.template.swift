
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
            path: "https://github.com/nbsfuse/fuse-ios/releases/download/:VERSION:/NBSFuse.xcframework.zip",
            checksum: ":CHECKSUM:"
        )
    ]
)
