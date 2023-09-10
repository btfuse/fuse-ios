// This is a generated file, do not modify directory


// swift-tools-version: 5.8

/*
Copyright 2023 Norman Breau

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
*/

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
