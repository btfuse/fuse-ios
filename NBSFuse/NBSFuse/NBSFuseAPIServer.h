
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

#ifndef NBSFuseAPIServer_h
#define NBSFuseAPIServer_h

#import "NBSFuseContext.h"
#include <sys/socket.h>
#include <netinet/in.h>
#include <arpa/inet.h>
#include <unistd.h>
#include <stdio.h>
#include <stdlib.h>
#include <pthread.h>

@interface NBSFuseAPIServer: NSObject <NSStreamDelegate> {
    @private
    NBSFuseContext* $context;
    int $sockFD;
    int $port;
//    dispatch_queue_t $connectionThread;
    NSString* $secret;
    pthread_t $mainNetworkThread;
}

- (instancetype) init NS_UNAVAILABLE;
- (instancetype) init:(NBSFuseContext*) context;
- (int) getPort;
- (NSString*) getSecret;
- (NBSFuseContext*) getContext;

@end

#endif /* NBSFuseAPIServer_h */
