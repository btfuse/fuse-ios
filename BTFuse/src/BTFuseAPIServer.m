
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

#import <Foundation/Foundation.h>
#import <CommonCrypto/CommonRandom.h>
#import <CoreFoundation/CoreFoundation.h>
#import "BTFuseAPIServer.h"
#import "BTFuseAPIResponse.h"
#import "BTFuseAPIPacket.h"
#import "BTFuseAPIRouter.h"
#import <BTFuse/BTFuseLogger.h>
#include <netinet/tcp.h>

struct BTFuseAPIServerClientConnection {
    BTFuseAPIServer* server;
    int client;
};

@interface BTFuseAPIServerHeaders: NSObject {
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

@implementation BTFuseAPIServerHeaders

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

@implementation BTFuseAPIServer {
    BTFuseContext* $context;
    int $sockFD;
    int $port;
    NSString* $secret;
    pthread_t $mainNetworkThread;
}

void* $handleClientConnection(void* dataPtr) {
    struct BTFuseAPIServerClientConnection* connection = (struct BTFuseAPIServerClientConnection*)dataPtr;
    BTFuseAPIServer* server = connection->server;
    int clientFD = connection->client;
    free(connection); // once we copied the clientFD then we don't need this struct anymore.
    BTFuseAPIServerHeaders* headers = $parseHeaders(clientFD);
    if (headers == nil) {
        close(clientFD);
        return NULL;
    }
    
    NSString* method = [headers getMethod];
    BTFuseLogger* logger = [[server getContext] getLogger];
    [logger info: @"API Server Request (%d): (%@) %@", clientFD, method, [headers getPath]];
    if ([method isEqualToString:@"OPTIONS"]) {
        BTFuseAPIResponse* res = [[[server getContext] getResponseFactory] create: [server getContext] socket: clientFD];
        [res sendNoContent];
        return NULL;
    }
    
    // TODO assert secret
    NSString* givenSecret = [headers getHeader:@"X-Fuse-Secret"];
    if (![[server getSecret] isEqualToString:givenSecret]) {
        close(clientFD);
        return NULL;
    }
    
    BTFuseAPIResponse* res = [[[server getContext] getResponseFactory] create: [server getContext] socket: clientFD];
    BTFuseAPIPacket* packet = [[BTFuseAPIPacket alloc] init: [server getContext] route:[headers getPath] withHeaders:[headers getHeaders] withSocket:clientFD];
    
    [[[server getContext] getAPIRouter] execute: packet withResponse: res];
    
    return NULL;
}

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

BTFuseAPIServerHeaders* $parseHeaders(int clientFD) {
    BTFuseAPIServerHeaders* headers = [[BTFuseAPIServerHeaders alloc] init];
    
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

- (instancetype) init:(BTFuseContext*) context {
    self = [super init];
    
    $context = context;
    
    BTFuseLogger* logger = [$context getLogger];
    
    $secret = $generateSecret();
    if ($secret == nil) {
        [logger error:@"BTFuseAPIServer: Secret Generation Failure"];
        return nil;
    }
    
    $sockFD = socket(PF_INET, SOCK_STREAM, IPPROTO_TCP);
    if ($sockFD == -1) {
        [logger error:@"BTFuseAPIServer: Socket Error"];
        return nil;
    }
    
    struct sockaddr_in server_addr;
    server_addr.sin_family = AF_INET;
    server_addr.sin_addr.s_addr = inet_addr("127.0.0.1");
    server_addr.sin_port = 0;
    
    if (bind($sockFD, (struct sockaddr*)&server_addr, sizeof(server_addr)) == -1) {
        [logger error:@"BTFuseAPIServer: Socket Bind Error"];
        close($sockFD);
        return nil;
    }
    
    socklen_t addr_len = sizeof(server_addr);
    if (getsockname($sockFD, (struct sockaddr *)&server_addr, &addr_len) == -1) {
        [logger error:@"BTFuseAPIServer: Socket Descriptor Error"];
        close($sockFD);
        return nil;
    }
    
    $port = ntohs(server_addr.sin_port);
    
    if (listen($sockFD, 255) == -1) {
        [logger error:@"BTFuseAPIServer: Could not listen to interface"];
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
    // This is a more graceful way of shutting down, but will involve adding a killswitch in the networkLoop.
    // shutdown($sockFD, SHUT_RDWR);
}

void* $networkLoop(void* ptr) {
    BTFuseAPIServer* self = (__bridge BTFuseAPIServer*)ptr;
    
    BTFuseLogger* logger = [[self getContext] getLogger];
    
    int sockFD = self->$sockFD;
    while (true) {
        int clientFD;
        struct sockaddr_in clientAddr;
        socklen_t clientAddrLen = sizeof(clientAddr);
        clientFD = accept(sockFD, (struct sockaddr*)&clientAddr, &clientAddrLen);

        if (clientFD == -1) {
            [logger error:@"Socket Acceptance Error"];
            continue;
        }

        int value = 1;
        int result = setsockopt(clientFD, SOL_SOCKET, SO_NOSIGPIPE, &value, sizeof(value));
        if (result == -1) {
            [logger error:@"Socket Configuration Error"];
            close(clientFD);
            continue;
        }
        
        struct BTFuseAPIServerClientConnection* client = (struct BTFuseAPIServerClientConnection*)malloc(sizeof(struct BTFuseAPIServerClientConnection));
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

- (BTFuseContext*) getContext {
    return $context;
}

@end
