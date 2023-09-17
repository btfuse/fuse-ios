
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

#import <Foundation/Foundation.h>
#import <NBSFuse/NBSFusePermissionRequest.h>

@implementation NBSFusePermissionRequest

- (instancetype) init:(NSArray<NSNumber*>*) permissionSet justified:(BOOL) justified {
    self = [super init];
    
    $permissionSet = permissionSet;
    $isJustified = justified;
    
    return self;
}

- (NSArray<NSNumber*>*) getPermissionSet {
    return $permissionSet;
}

- (BOOL) isJustified {
    return $isJustified;
}

@end
