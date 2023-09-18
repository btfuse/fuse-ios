
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
#import <CommonCrypto/CommonRandom.h>
#import <CoreFoundation/CoreFoundation.h>
#import "NBSFuseAPIServer.h"
#import "NBSFuseAPIResponse.h"
#import "NBSFuseAPIPacket.h"
#import "NBSFuseAPIRouter.h"
#include <netinet/tcp.h>

struct NBSFuseAPIServerClientConnection {
    NBSFuseAPIServer* server;
    int client;
};

@interface NBSFuseAPIServerHeaders: NSObject {
    NSMutableDictionary* $headers;
    NSString* $method;
    NSString* $version;
    NSString* $path;
}

- (instancetype) init NS_DESIGNATED_INITIALIZER;
- (NSString*) getMethod;
- (NSString*) getPath;
- (NSString*) getVersion;
- (NSString*) getHeader:(NSString*) name;
- (NSDictionary*) getHeaders;
- (void) setMethod:(NSString*) method;
- (void) setPath:(NSString*) path;
- (void) setVersion:(NSString*) version;
- (void) setHeader:(NSString*) name withValue:(NSString*) value;

@end

@implementation NBSFuseAPIServerHeaders

- (instancetype) init {
    self = [super init];

    $headers = [[NSMutableDictionary alloc] init];
    $method = nil;
    $version = nil;
    $path = nil;

    return self;
}

- (void) setMethod:(NSString*) method {
    $method = method;
}

- (void) setVersion:(NSString*) version {
    $version = version;
}

- (void) setPath:(NSString*) path {
    $path = path;
}

- (void) setHeader:(NSString*) name withValue:(NSString*) value {
    [$headers setObject:value forKey:name];
}

- (NSString*) getMethod {
    return $method;
}

- (NSString*) getVersion {
    return $version;
}

- (NSString*) getPath {
    return $path;
}

- (NSString*) getHeader:(NSString*) name {
    return [$headers objectForKey:name];
}

- (NSDictionary*) getHeaders {
    return $headers;
}

@end

@implementation NBSFuseAPIServer

void* $handleClientConnection(void* dataPtr) {
    struct NBSFuseAPIServerClientConnection* connection = (struct NBSFuseAPIServerClientConnection*)dataPtr;
    NBSFuseAPIServer* server = connection->server;
    int clientFD = connection->client;
    free(connection); // once we copied the clientFD then we don't need this struct anymore.
    NBSFuseAPIServerHeaders* headers = $parseHeaders(clientFD);
    if (headers == nil) {
        close(clientFD);
        return NULL;
    }
    
    NSString* method = [headers getMethod];
    if ([method isEqualToString:@"OPTIONS"]) {
        NBSFuseAPIResponse* res = [[NBSFuseAPIResponse alloc] init: clientFD];
        [res sendNoContent];
        return NULL;
    }
    
    // TODO assert secret
    NSString* givenSecret = [headers getHeader:@"X-Fuse-Secret"];
    if (![[server getSecret] isEqualToString:givenSecret]) {
        close(clientFD);
        return NULL;
    }
    
    NBSFuseAPIResponse* res = [[NBSFuseAPIResponse alloc] init: clientFD];
    NBSFuseAPIPacket* packet = [[NBSFuseAPIPacket alloc] init:[headers getPath] withHeaders:[headers getHeaders] withSocket:clientFD];
    
    [[[server getContext] getAPIRouter] execute: packet withResponse: res];
    
    return NULL;
}

- (void) stream:(NSStream*) stream handleEvent:(NSStreamEvent) eventCode {
    NSLog(@"stream event that probably needs to be handled...?");
    switch (eventCode) {
        case NSStreamEventNone:
            NSLog(@"NSStream None");
            break;
        case NSStreamEventOpenCompleted:
            NSLog(@"NSStream open");
            break;
        case NSStreamEventHasBytesAvailable:
            NSLog(@"NSStream bytes available for read");
            break;
        case NSStreamEventHasSpaceAvailable:
            NSLog(@"NSStream space available for write");
            break;
        case NSStreamEventErrorOccurred:
            NSLog(@"NSStream ERROR");
            break;
        case NSStreamEventEndEncountered:
            NSLog(@"NSStream END");
            break;
    }
}

//- (void) r

NSString* $generateSecret(void) {
    size_t secretLength = 32; // Length in bytes
    uint8_t secretBytes[secretLength];
    
    OSStatus status = SecRandomCopyBytes(kSecRandomDefault, secretLength, secretBytes);
    if (status != errSecSuccess) {
        // Handle the error, generating a secure random secret failed
        return nil;
    }
    
    NSMutableString *secretString = [NSMutableString stringWithCapacity:secretLength * 2];
    for (size_t i = 0; i < secretLength; i++) {
        [secretString appendFormat:@"%02x", secretBytes[i]];
    }
    
    return [secretString copy];
}

NSString* readLine(int clientFD) {
    NSMutableData* buffer = [[NSMutableData alloc] init];
    uint8_t p = '\0';
    uint8_t c = '\0';
    
    while (true) {
        ssize_t bytesRead = recv(clientFD, &c, sizeof(c), 0);
        
        if (bytesRead <= 0) {
            // connection closed or has partial data written
            // probably an error?
            break;
        }
        
        if (p == '\r' && c == '\n') {
            break;
        }
        
        if (c != '\r' && c != '\n') {
            [buffer appendBytes: &c length: sizeof(c)];
        }
        
        p = c;
    }
    
    if (buffer.length == 0) {
        return nil;
    }
    else {
        return [[NSString alloc] initWithData: buffer encoding: NSUTF8StringEncoding];
    }
}

NBSFuseAPIServerHeaders* $parseHeaders(int clientFD) {
    NBSFuseAPIServerHeaders* headers = [[NBSFuseAPIServerHeaders alloc] init];
    
    NSString* initialLine = readLine(clientFD);
    if (initialLine == nil) {
        return nil;
    }
    
    NSArray<NSString*>* initParts = [initialLine componentsSeparatedByString:@" "];
    if (initParts.count < 3) {
        return nil;
    }
    
    [headers setMethod: [initParts objectAtIndex: 0]];
    [headers setPath: [initParts objectAtIndex: 1]];
    [headers setVersion: [initParts objectAtIndex: 2]];
    
    while (true) {
        NSString* line = readLine(clientFD);

        if (line == nil) {
            break;
        }
        
        NSArray<NSString*>* parts = [line componentsSeparatedByString:@":"];
        NSString* headerKey = [parts[0] stringByTrimmingCharactersInSet: NSCharacterSet.whitespaceAndNewlineCharacterSet];
        NSString* headerValue;
        
        if (parts.count > 2) {
            // There was additional : in the value
            headerValue = [line substringFromIndex:headerKey.length + 1];
        }
        else {
            headerValue = parts[1];
        }
        
        [headers setHeader:headerKey withValue:[headerValue stringByTrimmingCharactersInSet: NSCharacterSet.whitespaceAndNewlineCharacterSet]];
    }
    
    return headers;
}

- (instancetype) init:(NBSFuseContext*) context {
    self = [super init];
    
    $context = context;
    
    $secret = $generateSecret();
    if ($secret == nil) {
        NSLog(@"NBSFuseAPIServer: Secret Generation Failure");
        return nil;
    }
    
    $sockFD = socket(PF_INET, SOCK_STREAM, IPPROTO_TCP);
    if ($sockFD == -1) {
        NSLog(@"NBSFuseAPIServer: Socket Error");
        return nil;
    }
    
    struct sockaddr_in server_addr;
    server_addr.sin_family = AF_INET;
    server_addr.sin_addr.s_addr = inet_addr("127.0.0.1");
    server_addr.sin_port = 0;
    
    if (bind($sockFD, (struct sockaddr*)&server_addr, sizeof(server_addr)) == -1) {
        NSLog(@"NBSFuseAPIServer: Socket Bind Error");
        close($sockFD);
        return nil;
    }
    
    socklen_t addr_len = sizeof(server_addr);
    if (getsockname($sockFD, (struct sockaddr *)&server_addr, &addr_len) == -1) {
        NSLog(@"NBSFuseAPIServer: Socket Descriptor Error");
        close($sockFD);
        return nil;
    }
    
    $port = ntohs(server_addr.sin_port);
    
    if (listen($sockFD, 255) == -1) {
        NSLog(@"NBSFuseAPIServer: Could not listen to interface");
        close($sockFD);
        return nil;
    }
    
    pthread_create(&$mainNetworkThread, NULL, &$networkLoop, (__bridge void *)(self));
    pthread_detach($mainNetworkThread);
    
    return self;
}

- (void) dealloc {
    close($sockFD);
    pthread_join($mainNetworkThread, NULL);
}

void* $networkLoop(void* ptr) {
    NBSFuseAPIServer* self = (__bridge NBSFuseAPIServer*)ptr;
    
    int sockFD = self->$sockFD;
    while (true) {
        int clientFD;
        struct sockaddr_in clientAddr;
        socklen_t clientAddrLen = sizeof(clientAddr);
        clientFD = accept(sockFD, (struct sockaddr*)&clientAddr, &clientAddrLen);

        if (clientFD == -1) {
            continue;
        }

        int value = 1;
        setsockopt(clientFD, SOL_SOCKET, SO_NOSIGPIPE, &value, sizeof(value));
        
        struct NBSFuseAPIServerClientConnection* client = (struct NBSFuseAPIServerClientConnection*)malloc(sizeof(struct NBSFuseAPIServerClientConnection));
        client->server = self;
        client->client = clientFD;

        // Could perhaps be refactored later to use an actual thread pool
        pthread_t connectionThread;
        pthread_create(&connectionThread, NULL, &$handleClientConnection, client);
        pthread_detach(connectionThread);
    }
    
    return NULL;
}

- (int) getPort {
    return $port;
}

- (NSString*) getSecret {
    return $secret;
}

- (NBSFuseContext*) getContext {
    return $context;
}

@end
