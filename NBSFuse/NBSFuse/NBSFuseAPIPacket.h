
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

#ifndef NBSFuseAPIPacket_h
#define NBSFuseAPIPacket_h

#import <Foundation/Foundation.h>

@interface NBSFuseAPIPacket: NSObject {
    @private
    NSString* $route;
    NSInputStream* $stream;
    NSDictionary* $headers;
}

- (instancetype) init NS_UNAVAILABLE;
- (instancetype) init:(NSString*) route withHeaders:(NSDictionary*) headers withStream:(NSInputStream*) inputStream NS_DESIGNATED_INITIALIZER;

- (NSString*) getRoute;
- (NSInputStream*) getStream;
- (unsigned long) getContentLength;
- (NSString*) getContentType;

- (NSString*) readAsString;
- (NSData*) readAsBinary;
- (NSDictionary*) readAsJSONObject:(NSError*) error;
- (NSArray*) readAsJSONArray:(NSError*) error;

@end

#endif
