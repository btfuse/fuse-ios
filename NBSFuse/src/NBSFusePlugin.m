
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

- (void) send:(NBSFuseAPIResponse*) response withData:(NSData*) data withType:(NSString*) type {
    [response finishHeaders:NBSFuseAPIResponseStatusOk withContentType:type withContentLength: data.length];
    [response pushData: data];
    [response didFinish];
}

- (void) send:(NBSFuseAPIResponse*) response withJSON:(NSDictionary*) data {
    NSError* serializationError;
    NSData* serialized = [NSJSONSerialization dataWithJSONObject:data options:NSJSONWritingPrettyPrinted error:&serializationError];
    if (serializationError != nil) {
        NSLog(@"Error domain: %@", serializationError.domain);
        NSLog(@"Error code: %ld", (long)serializationError.code);
        NSLog(@"Error description: %@", serializationError.localizedDescription);
        
        if (serializationError.localizedFailureReason) {
            NSLog(@"Failure reason: %@", serializationError.localizedFailureReason);
        }
        
        if (serializationError.localizedRecoverySuggestion) {
            NSLog(@"Recovery suggestion: %@", serializationError.localizedRecoverySuggestion);
        }
        
        NSLog(@"Error user info: %@", serializationError.userInfo);
        [response didInternalError];
        return;
    }
    [response finishHeaders:NBSFuseAPIResponseStatusOk withContentType:@"application/json" withContentLength: serialized.length];
    [response pushData:serialized];
    [response didFinish];
}

- (void) send:(NBSFuseAPIResponse*) response withString:(NSString*) data {
    [response finishHeaders:NBSFuseAPIResponseStatusOk withContentType:@"text/plain" withContentLength:[data length]];
    [response pushData: [data dataUsingEncoding:NSUTF8StringEncoding]];
    [response didFinish];
}

- (void) send:(NBSFuseAPIResponse*) response {
    [response finishHeaders:NBSFuseAPIResponseStatusOk withContentType:@"text/plain" withContentLength:0];
    [response didFinish];
}

- (void) sendError:(NBSFuseAPIResponse*) response withError:(NBSFuseError*) error {
    NSError* serializationError = nil;
    NSString* data = [error serialize:serializationError];
    if (serializationError != nil) {
        NSLog(@"Error domain: %@", serializationError.domain);
        NSLog(@"Error code: %ld", (long)serializationError.code);
        NSLog(@"Error description: %@", serializationError.localizedDescription);
        
        if (serializationError.localizedFailureReason) {
            NSLog(@"Failure reason: %@", serializationError.localizedFailureReason);
        }
        
        if (serializationError.localizedRecoverySuggestion) {
            NSLog(@"Recovery suggestion: %@", serializationError.localizedRecoverySuggestion);
        }
        
        NSLog(@"Error user info: %@", serializationError.userInfo);
        [response didInternalError];
        return;
    }
    
    [response finishHeaders:NBSFuseAPIResponseStatusError withContentType:@"application/json" withContentLength:[data length]];
    [response pushData: [data dataUsingEncoding:NSUTF8StringEncoding]];
    [response didFinish];
}

@end
