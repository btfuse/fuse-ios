
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

- (instancetype) init:(NBSFuseContext*) context {
    self = [super init:context];
    
    self.$resumeHandlers = [[NSMutableArray alloc] init];
    self.$pauseHandlers = [[NSMutableArray alloc] init];
    
    // Register for background and foreground notifications
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onPause) name:UIApplicationDidEnterBackgroundNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onResume) name:UIApplicationWillEnterForegroundNotification object:nil];
    
    return self;
}

- (void) initHandles {
    __weak NBSFuseRuntime* weakSelf = self;
    
    [self attachHandler:@"/info" callback:^void(NBSFuseAPIPacket* packet, NBSFuseAPIResponse* response) {
        [response sendJSON:[weakSelf getInfo]];
    }];
    
    [self attachHandler:@"/registerPauseHandler" callback:^(NBSFuseAPIPacket* packet, NBSFuseAPIResponse* response) {
        [weakSelf.$pauseHandlers addObject:[packet readAsString]];
        [response sendNoContent];
    }];
    
    [self attachHandler:@"/unregisterPauseHandler" callback:^(NBSFuseAPIPacket* packet, NBSFuseAPIResponse* response) {
        NSString* targetValue = [packet readAsString];
        NSInteger indexToRemove = [weakSelf.$pauseHandlers indexOfObjectPassingTest: ^BOOL (NSString* obj, NSUInteger idx, BOOL* stop) {
            return [obj isEqualToString: targetValue];
        }];
        
        if (indexToRemove != NSNotFound) {
            [weakSelf.$pauseHandlers removeObjectAtIndex:indexToRemove];
        }
        
        [response sendNoContent];
    }];
    
    [self attachHandler:@"/registerResumeHandler" callback:^(NBSFuseAPIPacket* packet, NBSFuseAPIResponse* response) {
        [weakSelf.$resumeHandlers addObject:[packet readAsString]];
        [response sendNoContent];
    }];
    
    [self attachHandler:@"/unregisterResumeHandler" callback:^(NBSFuseAPIPacket* packet, NBSFuseAPIResponse* response) {
        NSString* targetValue = [packet readAsString];
        NSInteger indexToRemove = [weakSelf.$resumeHandlers indexOfObjectPassingTest: ^BOOL (NSString* obj, NSUInteger idx, BOOL* stop) {
            return [obj isEqualToString: targetValue];
        }];
        
        if (indexToRemove != NSNotFound) {
            [weakSelf.$resumeHandlers removeObjectAtIndex:indexToRemove];
        }
        
        [response sendNoContent];
    }];
}

- (NSDictionary*) getInfo {
    UIDevice* device = [UIDevice currentDevice];
    
    NSString* version = [device systemVersion];
    
    return @{
        @"version": version
    };
}

- (void) onPause {
    @synchronized (self.$pauseHandlers) {
        for (id callbackID in self.$pauseHandlers) {
            [[self getContext] execCallback:callbackID];
        }
    }
}

- (void) onResume {
    @synchronized (self.$resumeHandlers) {
        for (id callbackID in self.$resumeHandlers) {
            [[self getContext] execCallback:callbackID];
        }
    }
}

@end
