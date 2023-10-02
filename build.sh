
#!/bin/sh

# Copyright 2023 Norman Breau 

# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at

#     http://www.apache.org/licenses/LICENSE-2.0

# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# Purpose
#
# Builds and prepares the project for release.
# If you're developing or contributing to the Fuse framework, you'll want to open
# the XCWorkspace in XCode instead.
#
# This script will 
#   1.  Clean your build environment for a fresh build.
#   2.  Run tests, this may take awhile.
#   3.  Copy files to a dist/ directory.

source build-tools/assertions.sh
source build-tools/DirectoryTools.sh
source build-tools/Checksum.sh

assertMac "Mac is required to build Fuse iOS"

echo "Building Fuse iOS Framework $(cat ./VERSION)..."

rm -rf dist
mkdir -p dist

echo "Cleaning the workspace..."
# Clean the build
# XCode can do a poor job in detecting if object code should recompile, particularly when messing with
# build configuration settings. This will ensure that the produced binary will be representative.
xcodebuild -quiet -workspace NBSFuse.xcworkspace -scheme NBSFuse -configuration Release -destination "generic/platform=iOS" clean
assertLastCall
xcodebuild -quiet -workspace NBSFuse.xcworkspace -scheme NBSFuse -configuration Debug -destination "generic/platform=iOS Simulator" clean
assertLastCall

echo "Building iOS framework..."
# Now build the iOS platform target in Release mode. We will continue to use Debug mode for iOS Simulator targets.
xcodebuild -quiet -workspace NBSFuse.xcworkspace -scheme NBSFuse -configuration Release -destination "generic/platform=iOS" build
assertLastCall
echo "Building iOS Simulator framework..."
xcodebuild -quiet -workspace NBSFuse.xcworkspace -scheme NBSFuse -configuration Debug -destination "generic/platform=iOS Simulator" build
assertLastCall

iosBuild=$(echo "$(xcodebuild -workspace NBSFuse.xcworkspace -scheme NBSFuse -configuration Release -sdk iphoneos -showBuildSettings | grep "CONFIGURATION_BUILD_DIR")" | cut -d'=' -f2 | xargs)
simBuild=$(echo "$(xcodebuild -workspace NBSFuse.xcworkspace -scheme NBSFuse -configuration Debug -sdk iphonesimulator -showBuildSettings | grep "CONFIGURATION_BUILD_DIR")" | cut -d'=' -f2 | xargs)

cp -r $iosBuild/NBSFuse.framework.dSYM ./dist/

echo "Packing XCFramework..."
xcodebuild -create-xcframework \
    -framework $iosBuild/NBSFuse.framework \
    -framework $simBuild/NBSFuse.framework \
    -output dist/NBSFuse.xcframework

spushd dist
    zip -r NBSFuse.xcframework.zip NBSFuse.xcframework > /dev/null
    zip -r NBSFuse.framework.dSYM.zip NBSFuse.framework.dSYM > /dev/null
    sha1_compute NBSFuse.xcframework.zip
    sha1_compute NBSFuse.framework.dSYM.zip
spopd
