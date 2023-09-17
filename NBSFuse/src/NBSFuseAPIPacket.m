
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

- (instancetype) init:(NSString*) route withHeaders:(NSDictionary*) headers withData:(NSData*) data {
    self = [super init];
    
    $route = route;
    $headers = headers;
    $data = data;
    
    return self;
}

- (NSString*) getRoute {
    return $route;
}

- (NSData*) getData {
    return $data;
}

- (unsigned long) getContentLength {
    return [[$headers valueForKey: @"Content-Length"] unsignedLongValue];
}

- (NSString*) getContentType {
    return [$headers valueForKey: @"Content-Type"];
}

- (NSString*) readAsString {
    return [[NSString alloc] initWithData: $data encoding: NSUTF8StringEncoding];
}

- (NSData*) readAsBinary {
    return $data;
}

- (NSDictionary*) readAsJSONObject:(NSError*) error {
    return [NSJSONSerialization JSONObjectWithData: $data options:NSJSONReadingMutableContainers error: &error];
}

- (NSArray*) readAsJSONArray:(NSError*) error {
    return [NSJSONSerialization JSONObjectWithData: $data options:NSJSONReadingMutableContainers error: &error];
}

@end
