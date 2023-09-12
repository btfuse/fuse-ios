
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

#import <NBSFuse/NBSFuseAPIResponse.h>

@implementation NBSFuseAPIResponse

- (instancetype)init:(id<WKURLSchemeTask>)task withURL:(NSURL *)requestURL {
    self = [self init];
    
    self.$task = task;
    self.$requestURL = requestURL;
    self.$hasSentHeaders = false;
    self.$status = NBSFuseAPIResponseStatusOk;
    self.$contentType = @"application/octet-stream";
    self.$contentLength = 0;
    
    return self;
}

- (void)setStatus:(NSUInteger)status {
    self.$status = status;
}

- (void) setContentType:(NSString*)contentType {
    self.$contentType = contentType;
}

- (void) setContentLength:(NSUInteger)length {
    self.$contentLength = length;
}

- (void) didFinishHeaders {
//    NSURLResponse* response = [[NSURLResponse alloc] initWithURL:self.$requestURL MIMEType:self.$contentType expectedContentLength:self.$contentLength textEncodingName:@"utf-8"];
    NSHTTPURLResponse* response = [
        [NSHTTPURLResponse alloc]
        initWithURL:self.$requestURL
        statusCode:self.$status
        HTTPVersion:@"HTTP/1.1"
        headerFields: @{
            @"Content-Type": self.$contentType,
            @"Content-Length": [NSString stringWithFormat:@"%lu", self.$contentLength]
        }
    ];
    [self.$task didReceiveResponse: response];
    self.$hasSentHeaders = true;
}

- (void) pushData:(NSData *)data {
    if (!self.$hasSentHeaders) {
        NSLog(@"Cannot send data before headers are sent. Must call finishHeaders first!");
        // TODO: Raise exception somehow
        return;
    }
    
    [self.$task didReceiveData: data];
}

- (void) didFinish {
    [self.$task didFinish];
}

- (void) didInternalError {
    [self setStatus:NBSFuseAPIResponseStatusInternalError];
    [self setContentType:@"text/plain"];
    NSString* msg = @"Internal Error. See native logs for more details";
    [self setContentLength:[msg length]];
    [self didFinishHeaders];
    [self pushData: [msg dataUsingEncoding:NSUTF8StringEncoding]];
    [self didFinish];
}

- (void) finishHeaders:(NSUInteger) status withContentType:(NSString*) contentType withContentLength:(NSUInteger) contentLength {
    [self setStatus:status];
    [self setContentType:contentType];
    [self setContentLength:contentLength];
    [self didFinishHeaders];
}

- (void) sendData:(NSData*) data {
    [self finishHeaders:NBSFuseAPIResponseStatusOk withContentType:@"application/octet-stream" withContentLength: data.length];
    [self pushData: data];
    [self didFinish];
}

- (void) sendData:(NSData*) data withType:(NSString*) type {
    [self finishHeaders:NBSFuseAPIResponseStatusOk withContentType:type withContentLength: data.length];
    [self pushData: data];
    [self didFinish];
}

- (void) sendJSON:(NSDictionary*) data {
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
        [self didInternalError];
        return;
    }
    [self finishHeaders:NBSFuseAPIResponseStatusOk withContentType:@"application/json" withContentLength: serialized.length];
    [self pushData:serialized];
    [self didFinish];
}

- (void) sendString:(NSString*) data {
    [self finishHeaders:NBSFuseAPIResponseStatusOk withContentType:@"text/plain" withContentLength:[data length]];
    [self pushData: [data dataUsingEncoding:NSUTF8StringEncoding]];
    [self didFinish];
}

- (void) sendNoContent {
    [self finishHeaders:NBSFuseAPIResponseStatusOk withContentType:@"text/plain" withContentLength:0];
    [self didFinish];
}

- (void) sendError:(NBSFuseError*) error {
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
        [self didInternalError];
        return;
    }
    
    [self finishHeaders:NBSFuseAPIResponseStatusError withContentType:@"application/json" withContentLength:[data length]];
    [self pushData: [data dataUsingEncoding:NSUTF8StringEncoding]];
    [self didFinish];
}

@end
