
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

#import <NBSFuse/NBSFuseAPIPacket.h>

@implementation NBSFuseAPIPacket

- (instancetype) init:(NSString*) route withHeaders:(NSDictionary*) headers withStream:(NSInputStream*) inputStream {
    self = [super init];
    
    $route = route;
    $headers = headers;
    $stream = inputStream;
    
    return self;
}

- (NSString*) getRoute {
    return $route;
}

- (NSInputStream*) getStream {
    return $stream;
}

- (unsigned long) getContentLength {
    NSString* value = [$headers valueForKey: @"Content-Length"];
    return value.longLongValue;
}

- (NSString*) getContentType {
    return [$headers valueForKey: @"Content-Type"];
}

- (NSString*) readAsString {
    NSData* data = [self readAsBinary];
    return [[NSString alloc] initWithData: data encoding: NSUTF8StringEncoding];
}

- (NSData*) readAsBinary {
    unsigned long contentLength = [self getContentLength];
    NSMutableData* data = [[NSMutableData alloc] initWithLength: contentLength];
    
    NSUInteger bytesRead = 0;
    NSUInteger bytesToRead = contentLength;

    while (bytesRead < contentLength) {
        NSInteger result = [$stream read:[data mutableBytes] + bytesRead maxLength:bytesToRead];
        
        if (result <= 0) {
            // Handle error or end of stream
            break;
        }
        
        bytesRead += result;
        bytesToRead -= result;
    }
    
    return data;
}

- (NSDictionary*) readAsJSONObject:(NSError*) error {
    NSData* data = [self readAsBinary];
    return [NSJSONSerialization JSONObjectWithData: data options:NSJSONReadingMutableContainers error: &error];
}

- (NSArray*) readAsJSONArray:(NSError*) error {
    NSData* data = [self readAsBinary];
    return [NSJSONSerialization JSONObjectWithData: data options:NSJSONReadingMutableContainers error: &error];
}

@end
