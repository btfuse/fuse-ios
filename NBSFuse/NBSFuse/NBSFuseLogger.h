
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

#ifndef NBSFuseLogger_h
#define NBSFuseLogger_h

#import <NBSFuse/NBSFuseLoggerLevel.h>

@class NBSFuseContext;

@interface NBSFuseLogger: NSObject

- (instancetype) init NS_UNAVAILABLE;
- (instancetype) init:(NBSFuseContext*) context NS_DESIGNATED_INITIALIZER;

- (void) setLevel:(NBSFuseLoggerLevel) level;
- (NBSFuseLoggerLevel) getLevel;

- (void) setCallbackID:(NSString*) callbackID;

- (void) debug:(NSString*) format, ... NS_FORMAT_FUNCTION(1, 2);
- (void) info:(NSString*) format, ... NS_FORMAT_FUNCTION(1, 2);
- (void) warn:(NSString*) format, ... NS_FORMAT_FUNCTION(1, 2);
- (void) error:(NSString*) format, ... NS_FORMAT_FUNCTION(1, 2);

@end

#endif
