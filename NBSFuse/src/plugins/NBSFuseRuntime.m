
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

#import "NBSFuseRuntime.h"
#import <NBSFuse/NBSFuseContext.h>
#import <UIKit/UIKit.h>
#import <NBSFuse/NBSFuseError.h>

@implementation NBSFuseRuntime

- (NSString*) getID {
    return @"FuseRuntime";
}

- (void) initHandles {
    __weak NBSFuseRuntime* weakSelf = self;
    
    [self attachHandler:@"/info" callback:^void(NSData *data, NBSFuseAPIResponse* response) {
        [weakSelf getInfo:data withResponse:response];
    }];
}

- (void) getInfo:(NSData*)data withResponse:(NBSFuseAPIResponse*) response {
    NSDictionary* runtimeData = [self getInfo];
    [self send:response withJSON: runtimeData];
}

- (NSDictionary*) getInfo {
    UIDevice* device = [UIDevice currentDevice];
    
    NSString* version = [device systemVersion];
    
    return @{
        @"version": version
    };
}

@end
