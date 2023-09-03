
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
#import <NBSFuseAPIRouter.h>
#import <NBSFuse/NBSFuseContext.h>
#import <NBSFuse/NBSFusePlugin.h>
#import <NBSFuse/NBSFuseError.h>

@implementation NBSFuseAPIRouter

- (instancetype) init: (NBSFuseContext*) context {
    self = [super init];
    
    self.$context = context;
    
    return self;
}

//NSString* buildError(NSInteger code, NSString* message)

- (void) execute:(NBSFuseAPIPacket*) packet withResponse:(NBSFuseAPIResponse*) response {
    // TODO:
    // Route packet to proper plugin and delegate the action, receive a NBSFuseAPIResponse back.
    NSString* route = [packet getRoute];
    
    NSArray* parts = [route componentsSeparatedByString: @"/"];
    
    if ([parts count] < 3) {
        [response setStatus:NBSFuseAPIResponseStatusError];
        [response setContentType:@"application/json"];
        NSError* error = nil;
        NSString* message = [[[NBSFuseError alloc] init:@"NBSFuseAPIRouter" withCode:1 withMessage:@"Malformed route"] serialize:error];
        NSData* msgData = [message dataUsingEncoding:NSUTF8StringEncoding];
        [response setContentLength: [msgData length]];
        [response didFinishHeaders];
        [response pushData:msgData];
        [response didFinish];
        return;
    }
    
    NSString* pluginID = [parts objectAtIndex: 2];
    NBSFusePlugin* plugin = [self.$context getPlugin: pluginID];
    if (plugin == nil) {
        [response setStatus:NBSFuseAPIResponseStatusError];
        [response setContentType:@"application/json"];
        NSError* error = nil;
        NSString* message = [[[NBSFuseError alloc] init:@"NBSFuseAPIRouter" withCode:2 withMessage:@"Unknown Plugin"] serialize:error];
        NSData* msgData = [message dataUsingEncoding:NSUTF8StringEncoding];
        [response setContentLength: [msgData length]];
        [response didFinishHeaders];
        [response pushData:msgData];
        [response didFinish];
        return;
    }
    
    NSMutableArray* components = [parts mutableCopy];
    
    [components removeObjectsInRange: NSMakeRange(0, 3)]; //Removes /, api, and the plugin ID from components, and leaves /methodName
    NSString* servicePath = [@"/" stringByAppendingString:[components componentsJoinedByString:@"/"]];
    
    [plugin route: servicePath data: [packet getData] withResponse: response];
}

@end
