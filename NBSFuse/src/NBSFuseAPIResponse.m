
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

- (void)setStatus:(NBSFuseAPIResponseStatus)status {
    self.$status = status;
}

- (void) setContentType:(NSString*)contentType {
    self.$contentType = contentType;
}

- (void) setContentLength:(NSUInteger)length {
    self.$contentLength = length;
}

- (void) didFinishHeaders {
    int statusCode = 0;
    switch (self.$status) {
        case NBSFuseAPIResponseStatusOk:
            statusCode = 200;
            break;
        case NBSFuseAPIResponseStatusError:
            statusCode = 400;
            break;
    }
    
    NSURLResponse* response = [[NSURLResponse alloc] initWithURL:self.$requestURL MIMEType:self.$contentType expectedContentLength:self.$contentLength textEncodingName:@"utf-8"];
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

@end
