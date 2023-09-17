
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
#import <NBSFuse/NBSFuseError.h>

@implementation NBSFuseError

- (instancetype)init:(NSString *)domain withCode:(NSInteger)code withMessage:(NSString *)message {
    self = [super init];
    
    $domain = domain;
    $message = message;
    $code = code;
    
    return self;
}

- (instancetype)init:(NSString *)domain withCode:(NSInteger)code withError:(NSError *)error {
    return [self init:domain withCode:code withMessage:[error localizedDescription]];
}

- (NSInteger)getCode {
    return $code;
}

- (NSString *)getDomain {
    return $domain;
}

- (NSString *)getMessage {
    return $message;
}

- (NSString *)serialize:(NSError*) error {
    NSDictionary* obj = @{
        @"domain": $domain,
        @"code": [[NSNumber alloc] initWithInteger: $code],
        @"message": $message
    };
    
    NSString* serialized = [[NSString alloc] initWithData:[NSJSONSerialization dataWithJSONObject:obj options:0 error:&error] encoding: NSUTF8StringEncoding];
    
    return serialized;
}

@end
