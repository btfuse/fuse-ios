
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

#import <NBSFuse/NBSFuseLogger.h>
#import <NBSFuse/NBSFuseContext.h>

@implementation NBSFuseLogger {
    NBSFuseLoggerLevel $level;
    NBSFuseContext* $context;
    NSString* $callbackID;
}

- (instancetype) init:(NBSFuseContext*) context {
    self = [super init];
    
    $context = context;
    $level = NBSFuseLoggerLevelInfo | NBSFuseLoggerLevelWarn | NBSFuseLoggerLevelError;
    
    #ifdef DEBUG
        $level |= NBSFuseLoggerLevelDebug;
    #endif
    
    return self;
}

- (void) setLevel:(NBSFuseLoggerLevel) level {
    $level = level;
}

- (NBSFuseLoggerLevel) getLevel {
    return $level;
}

- (void) setCallbackID:(NSString*) callbackID {
    $callbackID = callbackID;
}

- (void) $bridgeToWebview:(NBSFuseLoggerLevel) level message:(NSString*) message {
    if ($callbackID == nil) {
        return;
    }
    
    NSDictionary* packet = @{
        @"level": @(level),
        @"message": message
    };
    
    NSError* error = nil;
    NSData* serialized = [NSJSONSerialization dataWithJSONObject: packet options: 0 error: &error];

    if (!serialized) {
        NSLog(@"Packet Serialization Error: %@", error);
        return;
    }
    
    NSString* json = [[NSString alloc] initWithData: serialized encoding: NSUTF8StringEncoding];
    [$context execCallback: $callbackID withData:json];
}

- (void) debug:(NSString*) format, ... __attribute__((format(NSString, 1, 2))) {
    if (!($level & NBSFuseLoggerLevelDebug)) {
        return;
    }
    
    va_list args;
    va_start(args, format);
    NSString* message = [[NSString alloc] initWithFormat:format arguments:args];
    va_end(args);
    
    NSLog(@"[%@]: %@", NBSFuseLoggerLevel_toString(NBSFuseLoggerLevelDebug), message);
    [self $bridgeToWebview:NBSFuseLoggerLevelDebug message: message];
}

- (void) info:(NSString*) format, ... __attribute__((format(NSString, 1, 2))) {
    if (!($level & NBSFuseLoggerLevelInfo)) {
        return;
    }
    
    va_list args;
    va_start(args, format);
    NSString* message = [[NSString alloc] initWithFormat:format arguments:args];
    va_end(args);
    
    NSLog(@"[%@]: %@", NBSFuseLoggerLevel_toString(NBSFuseLoggerLevelInfo), message);
    [self $bridgeToWebview:NBSFuseLoggerLevelInfo message: message];
}

- (void) warn:(NSString*) format, ... __attribute__((format(NSString, 1, 2))) {
    if (!($level & NBSFuseLoggerLevelWarn)) {
        return;
    }
    
    va_list args;
    va_start(args, format);
    NSString* message = [[NSString alloc] initWithFormat:format arguments:args];
    va_end(args);
    
    NSLog(@"[%@]: %@", NBSFuseLoggerLevel_toString(NBSFuseLoggerLevelWarn), message);
    [self $bridgeToWebview:NBSFuseLoggerLevelWarn message: message];
}

- (void) error:(NSString*) format, ... __attribute__((format(NSString, 1, 2))) {
    if (!($level & NBSFuseLoggerLevelError)) {
        return;
    }
    
    va_list args;
    va_start(args, format);
    NSString* message = [[NSString alloc] initWithFormat:format arguments:args];
    va_end(args);
    
    NSLog(@"[%@]: %@", NBSFuseLoggerLevel_toString(NBSFuseLoggerLevelError), message);
    [self $bridgeToWebview:NBSFuseLoggerLevelError message: message];
}

@end
