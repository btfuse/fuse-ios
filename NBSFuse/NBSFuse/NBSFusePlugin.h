
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

#ifndef NBSFusePlugin_h
#define NBSFusePlugin_h

#import <Foundation/Foundation.h>
#import <NBSFuse/NBSFuseAPIResponse.h>
#import <NBSFuse/NBSFuseError.h>

typedef void (^NBSFusePluginAPIHandle)(NSData* data, NBSFuseAPIResponse* response);

@class NBSFuseContext;

@protocol NBSFusePluginProtocol <NSObject>

- (NSString*)getID;
//- (NSString*)handle:(NSString*)method data:(NSData*)data;

@end

@interface NBSFusePlugin: NSObject <NBSFusePluginProtocol>

@property (nonatomic, strong) NSMutableDictionary<NSString*, NBSFusePluginAPIHandle>* $handles;
@property (nonatomic, weak) NBSFuseContext* $context;

- (instancetype) init:(NBSFuseContext*)context;

- (void) route:(NSString*)path data:(NSData*)data withResponse:(NBSFuseAPIResponse*) response;

- (void) initHandles;
- (void) attachHandler:(NSString*) path callback:(NBSFusePluginAPIHandle)callback;

- (NBSFuseContext*) getContext;

// Convenience methods, if you don't need to chunk data
- (void) send:(NBSFuseAPIResponse*) response withString:(NSString*) data;
- (void) send:(NBSFuseAPIResponse*) response withData:(NSDate*) data withType:(NSString*) type;
- (void) send:(NBSFuseAPIResponse*) response withJSON:(NSDictionary*) data;
- (void) sendError:(NBSFuseAPIResponse*) response withError:(NBSFuseError*) error;

@end

#endif /* NBSFusePlugih_h */
