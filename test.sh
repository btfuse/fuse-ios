#!/bin/bash

# Copyright 2023 Breautek 

# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at

#     http://www.apache.org/licenses/LICENSE-2.0

# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

IOS_15=$(python3 ./build-tools/iossim.py "Fuse iOS 15" "iOS 15.5" "iPhone 13")
IOS_16=$(python3 ./build-tools/iossim.py "Fuse iOS 16" "iOS 16.4" "iPhone 14")
IOS_17=$(python3 ./build-tools/iossim.py "Fuse iOS 17" "iOS 17.0" "iPhone 15")

xcrun simctl boot $IOS_15 > /dev/null
xcrun simctl boot $IOS_16 > /dev/null
xcrun simctl boot $IOS_17 > /dev/null

ios15Check="0"
ios16Check="0"
ios17Check="0"

xcodebuild -quiet test -workspace BTFuse.xcworkspace -scheme BTFuseTests -enableCodeCoverage YES -destination-timeout 60 -destination "id=$IOS_15"
ios15Check=$?
xcodebuild -quiet test -workspace BTFuse.xcworkspace -scheme BTFuseTests -enableCodeCoverage YES -destination-timeout 60 -destination "id=$IOS_16"
ios16Check=$?
xcodebuild -quiet test -workspace BTFuse.xcworkspace -scheme BTFuseTests -enableCodeCoverage YES -destination-timeout 60 -destination "id=$IOS_17"
ios17Check=$?

if [ "$ios15Check" -ne "0" ]; then
    echo "iOS 15 tests failed."
else
    echo "iOS 15 tests passed."
fi

if [ "$ios16Check" -ne "0" ]; then
    echo "iOS 16 tests failed."
else
    echo "iOS 16 tests passed."
fi

if [ "$ios17Check" -ne "0" ]; then
    echo "iOS 17 tests failed."
else
    echo "iOS 17 tests passed."
fi

exit $ios15Check || $ios16Check || $ios17Check || 0
