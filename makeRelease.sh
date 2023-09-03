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

REPO="fuse-ios"

cd ..
source compiler/_assertCleanWorkspace.sh
source compiler/_assertMac.sh
cd fuse-ios

VERSION="$1"

if [ -z "$VERSION" ]; then
    echo "Version is required."
    exit 2
fi

cd ..
source compiler/_assertGitTag.sh
cd fuse-ios

echo $VERSION > VERSION

cd ..
./build.sh ios
cd fuse-ios

rm -f ./build/NBSFuse.xcframework.zip
rm -f ./build/NBSFuse-debug.xcframework.zip

zip ./build/NBSFuse.xcframework.zip -r ./build/NBSFuse.xcframework
zip ./build/NBSFuse-debug.xcframework.zip -r ./build/NBSFuse-debug.xcframework

rm -rf build/dist
mkdir -p build/dist/NBSFuse
cp -r build/NBSFuse.xcframework build/dist/NBSFuse/
cp -r build/NBSFuse-debug.xcframework build/dist/NBSFuse/
cp LICENSE build/dist/NBSFuse/

rm -f build/NBSFuse.zip
cd build/dist
zip NBSFuse.zip -r NBSFuse
cd ../..
mv build/dist/NBSFuse.zip build/

CHECKSUM="$(shasum -a 1 build/NBSFuse.zip  | cut -d ' ' -f 1)"

# Generate the podspec. Unfortunately due to how podspecs work, they need access to any files
# they reference, so we can't read from VERSION in the podspec itself.
echo "# This is a generated file, do not modify directory\n\n" > NBSFuse.podspec
echo "$(cat NBSFuse.template.podspec)" >> NBSFuse.podspec
sed -i '' "s/:VERSION:/$VERSION/g" NBSFuse.podspec
sed -i '' "s/:CHECKSUM:/$CHECKSUM/g" NBSFuse.podspec

git add VERSION
git commit -m "iOS Release: $VERSION"
git push
git tag -a $VERSION -m "iOS Release: $VERSION"
git push --tags

gh release create $VERSION \
    ./build/NBSFuse.zip \
    ./build/NBSFuse.xcframework.zip \
    ./build/NBSFuse-debug.xcframework.zip \
    --verify-tag --generate-notes

pod repo push nbs NBSFuse.podspec
