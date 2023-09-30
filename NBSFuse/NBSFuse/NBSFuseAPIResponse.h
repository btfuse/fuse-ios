
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

#ifndef NBSFuseAPIResponse_h
#define NBSFuseAPIResponse_h

#import <WebKit/WebKit.h>
#import <NBSFuse/NBSFuseError.h>

typedef NS_ENUM(NSUInteger, NBSFuseAPIResponseStatus) {
    NBSFuseAPIResponseStatusOk = 200,
    NBSFuseAPIResponseStatusError = 400,
    NBSFuseAPIResponseStatusInternalError = 500
};

@interface NBSFuseAPIResponse: NSObject {
    int $client;
    bool $hasSentHeaders;
    bool $isClosed;
    NSUInteger $status;
    NSUInteger $contentLength;
    NSString* $contentType;
    dispatch_queue_t $networkQueue;
}

- (instancetype) init NS_UNAVAILABLE;
//- (instancetype) init: (id<WKURLSchemeTask>) task withURL:(NSURL*) requestURL NS_DESIGNATED_INITIALIZER;
- (instancetype) init:(int) client NS_DESIGNATED_INITIALIZER;

// Header APIs
- (void) setStatus:(NSUInteger) status;
- (NSString*) getStatusText:(NSUInteger) status;
- (void) setContentLength:(NSUInteger) length;
- (void) setContentType:(NSString*) contentType;
- (void) didFinishHeaders;
- (void) finishHeaders:(NSUInteger) status withContentType:(NSString*) contentType withContentLength:(NSUInteger) contentLength;

// Data APIs
- (void) pushData:(NSData*) data;
- (void) didFinish;

- (void) didInternalError;
- (bool) isClosed;

// Convenience methods, if you don't need to chunk data
- (void) sendString:(NSString*) data;
- (void) sendData:(NSData*) data;
- (void) sendData:(NSDate*) data withType:(NSString*) type;
- (void) sendJSON:(NSDictionary*) data;
- (void) sendNoContent;
- (void) sendError:(NBSFuseError*) error;

- (void) kill:(NSString*) message;

@end

#endif
