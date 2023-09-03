
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

typedef NS_ENUM(NSInteger, NBSFuseAPIResponseStatus) {
    NBSFuseAPIResponseStatusOk,
    NBSFuseAPIResponseStatusError
};

@interface NBSFuseAPIResponse: NSObject

@property (nonatomic, assign) bool $hasSentHeaders;
@property (nonatomic, strong) NSURL* $requestURL;
@property (nonatomic, assign) id<WKURLSchemeTask> $task;
@property (nonatomic, strong) NSString* $contentType;
@property (nonatomic, assign) NSUInteger $contentLength;
@property (nonatomic, assign) NBSFuseAPIResponseStatus $status;

- (instancetype) init: (id<WKURLSchemeTask>) task withURL:(NSURL*) requestURL;

// Header APIs
- (void) setStatus:(NBSFuseAPIResponseStatus) status;
- (void) setContentLength:(NSUInteger) length;
- (void) setContentType:(NSString*) contentType;
- (void) didFinishHeaders;

// Data APIs
- (void) pushData:(NSData*) data;
- (void) didFinish;

@end

#endif /* NBSFuseAPIResponse_h */
