
/*
Copyright 2023 Breautek

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

#import <BTFuse/BTFuseAPIPacket.h>
#import <BTFuse/BTFuseContext.h>
#import <BTFuse/BTFuseLogger.h>

@implementation BTFuseAPIPacket {
    NSString* $route;
    BTFuseAPIClient* $client;
    NSDictionary* $headers;
    BTFuseContext* $context;
}

- (instancetype) init:(BTFuseContext*) context route:(NSString*) route headers:(NSDictionary*) headers client:(BTFuseAPIClient*) client {
    self = [super init];
    
    $context = context;
    $route = route;
    $headers = headers;
    $client = client;
    
    return self;
}

- (NSString*) getRoute {
    return $route;
}

- (BTFuseAPIClient*) getClient {
    return $client;
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
    
    NSMutableData* buffer = [[NSMutableData alloc] init];
    [$client read:buffer length: (uint32_t) contentLength];
    
    return buffer;
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
