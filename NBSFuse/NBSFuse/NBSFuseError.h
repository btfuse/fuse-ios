
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

#ifndef NBSFuseError_h
#define NBSFuseError_h

@interface NBSFuseError: NSObject {
    @private
    NSInteger $code;
    NSString* $domain;
    NSString* $message;
}

- (instancetype) init NS_UNAVAILABLE;
- (instancetype) init:(NSString*) domain withCode:(NSInteger) code withMessage:(NSString*) message NS_DESIGNATED_INITIALIZER;
- (instancetype) init:(NSString*) domain withCode:(NSInteger) code withError:(NSError*) error;

- (NSString*) getDomain;
- (NSString*) getMessage;
- (NSInteger) getCode;

- (NSString*) serialize: (NSError*)error;

@end

#endif
