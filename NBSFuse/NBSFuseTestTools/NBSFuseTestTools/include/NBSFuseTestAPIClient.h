
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

#ifndef NBSFuseTestAPIClient_h
#define NBSFuseTestAPIClient_h

@interface NBSFuseTestAPIClientResponse: NSObject

@property (nonatomic, strong) NSNumber* _Nonnull status;
@property (nonatomic, strong) NSData* _Nonnull data;

- (nonnull instancetype) init NS_UNAVAILABLE;
- (nonnull instancetype) initWithCode:(nonnull NSNumber*) code data:(nonnull NSData*) data NS_DESIGNATED_INITIALIZER;

@end

typedef void (^NBSFuseTestAPIClientCallback)(NSError* _Nullable error, NBSFuseTestAPIClientResponse* _Nullable response);

@interface NBSFuseTestAPIClient: NSObject
- (nonnull instancetype) init NS_UNAVAILABLE;
- (nonnull instancetype) init:(nonnull NSString*) pluginID
    secret:(nonnull NSString*) secret
    port:(int) port
    endpoint:(nonnull NSString*) endpoint
    data:(nullable NSData*) data
    type:(nullable NSString*) type;

- (void) execute:(nonnull NBSFuseTestAPIClientCallback) callback;

@end

@interface NBSFuseTestAPIClientBuilder: NSObject

@property (nonatomic, strong) NSString* _Nonnull pluginID;
@property (nonatomic, strong) NSNumber* _Nonnull apiPort;
@property (nonatomic, strong) NSString* _Nonnull apiSecret;
@property (nonatomic, strong) NSString* _Nonnull endpoint;
@property (nonatomic, strong) NSData* _Nullable data;
@property (nonatomic, strong) NSString* _Nullable contentType;

- (nonnull NBSFuseTestAPIClient*) build;

@end

#endif
