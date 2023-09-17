
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

#ifndef NBSFusePermissionRequest_h
#define NBSFusePermissionRequest_h

@interface NBSFusePermissionRequest: NSObject {
    @private
        NSArray<NSNumber*>* $permissionSet;
        BOOL $isJustified;
}

- (instancetype) init NS_UNAVAILABLE;

- (instancetype) init:(NSArray<NSNumber*>*) permissionSet justified:(BOOL) justified NS_DESIGNATED_INITIALIZER;

- (NSArray<NSNumber*>*) getPermissionSet;
- (BOOL) isJustified;

@end

#endif
