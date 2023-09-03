
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
#import <NBSFuse/NBSFusePlugin.h>
#import <NBSFuse/NBSFuseContext.h>
#import <NBSFuse/NBSFuseError.h>

@implementation NBSFusePlugin

- (instancetype)init:(NBSFuseContext*)context {
    self = [super init];
    
    self.$context = context;
    self.$handles = [[NSMutableDictionary alloc] init];
    [self initHandles];
    
    return self;
}

- (NBSFuseContext*) getContext {
    return self.$context;
}

- (NSString*)getID {
    NSAssert(NO, @"NBSFusePlugin.getID is abstract and must be overwritten by the concrete class.");
    return nil;
}

- (void) route:(NSString*) path data:(NSData*) data withResponse:(NBSFuseAPIResponse*) response {
    NBSFusePluginAPIHandle apiHandle = [self.$handles objectForKey: path];
    if (apiHandle == nil) {
        [response setStatus:NBSFuseAPIResponseStatusError];
        [response setContentType:@"application/json"];
        NSError* error = nil;
        NSString* message = [[[NBSFuseError alloc] init:@"NBSFusePlugin" withCode:1 withMessage:@"No Handler"] serialize:error];
        NSData* msgData = [message dataUsingEncoding:NSUTF8StringEncoding];
        [response setContentLength: [msgData length]];
        [response didFinishHeaders];
        [response pushData:msgData];
        [response didFinish];
        return;
    }
    
    apiHandle(data, response);
}

- (void) attachHandler:(NSString *)path callback:(NBSFusePluginAPIHandle)callback {
    [self.$handles setObject:callback forKey:path];
}

- (void) initHandles {}

@end
