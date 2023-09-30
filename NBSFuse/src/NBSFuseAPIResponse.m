
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
#import <NBSFuse/NBSFuseAPIResponse.h>
#include <sys/socket.h>
#include <pthread.h>

typedef void (^NBSFuseAPIResponse_TaskBlock)(void);

@implementation NBSFuseAPIResponse {
    pthread_mutex_t $workerMutex;
    pthread_t $workerThread;
    NSMutableArray<NBSFuseAPIResponse_TaskBlock>* $workerQueue;
}

void* $NBSFuseAPIResponse_processTask(void* pdata) {
    NBSFuseAPIResponse* res = (__bridge NBSFuseAPIResponse*)pdata;
    
    pthread_mutex_t* workerMutex = [res __getWorkerMutex];
    
    while (true) {
        if (![res isClosed]) {
            pthread_mutex_lock(workerMutex);
        }
        else {
            break;
        }
        
        while ([res __hasTaskAvailable]) {
            NBSFuseAPIResponse_TaskBlock task = [res __getNextTask];
            task();
        }
    }
    
    return NULL;
}

- (instancetype) init:(int) client {
    self = [super init];
    
    $client = client;
    if (pthread_mutex_init(&$workerMutex, NULL) != 0) {
        NSLog(@"Worker Mutex Init Failure");
        return nil;
    }
    
    $workerQueue = [[NSMutableArray alloc] init];
    $isClosed = false;
    $hasSentHeaders = false;
    $status = NBSFuseAPIResponseStatusOk;
    $contentLength = 0;
    $contentType = @"application/octet-stream";
    
    pthread_create(&self->$workerThread, NULL, &$NBSFuseAPIResponse_processTask, (__bridge void *)(self));
    
    return self;
}

- (pthread_mutex_t*) __getWorkerMutex {
    return &$workerMutex;
}

- (bool) __hasTaskAvailable {
    @synchronized ($workerQueue) {
        return [$workerQueue count] > 0;
    }
}

- (void) __addNetworkingTask:(NBSFuseAPIResponse_TaskBlock) task {
    @synchronized ($workerQueue) {
        [$workerQueue addObject:task];
        pthread_mutex_unlock(&$workerMutex);
    }
}

- (NBSFuseAPIResponse_TaskBlock) __getNextTask {
    @synchronized ($workerQueue) {
        NBSFuseAPIResponse_TaskBlock task = [$workerQueue firstObject];
        [$workerQueue removeObjectAtIndex: 0];
        return task;
    }
}

- (void) $kill:(NSString*) message {
    if ($isClosed) {
        return;
    }
    
    NSLog(@"Killing %d for reason: %@", $client, message);
    $isClosed = true;
    close($client);
}

- (ssize_t) $write:(const void*) data length:(size_t) length {
    return write($client, data, length);
}

- (void) write:(const void*) sourceData length:(size_t) length {
    void* data = malloc(length);
    memcpy(data, sourceData, length);
    [self __addNetworkingTask:^{
        #pragma clang diagnostic push
        #pragma clang diagnostic ignored "-Warc-retain-cycles"
        /*
            The block is stored temporary and removed when processed later,
            thus retain cycles should be a non-issue here.
         */
        if ([self isClosed]) {
            return;
        }
        
        NSLog(@"Writing to %d", self->$client);
        ssize_t bytesWritten = [self $write:data length: length];
        free(data);
        if (bytesWritten < 0) {
            [self $kill:@"Network Socket Error"];
        }
        #pragma clang diagnostic pop
    }];
}

- (void) setStatus:(NSUInteger)status {
    $status = status;
}

- (void) setContentType:(NSString*)contentType {
    $contentType = contentType;
}

- (void) setContentLength:(NSUInteger)length {
    $contentLength = length;
}

- (bool) isClosed {
    return $isClosed;
}

- (void) didFinishHeaders {
    $hasSentHeaders = true;
    
    NSMutableString* headers = [[NSMutableString alloc] initWithString:@"HTTP/1.1"];
    [headers appendString:[NSString stringWithFormat:@" %lu %@\r\n", $status, [self getStatusText:$status]]];
    [headers appendString:[NSString stringWithFormat:@"Access-Control-Allow-Origin: %@\r\n", @"nbsfuse://localhost"]];
    [headers appendString:[NSString stringWithFormat:@"Access-Control-Allow-Headers: %@\r\n", @"*"]];
    [headers appendString:[NSString stringWithFormat:@"Cache-Control: %@\r\n", @"no-cache"]];
    [headers appendString:[NSString stringWithFormat:@"Content-Type: %@\r\n", $contentType]];
    [headers appendString:[NSString stringWithFormat:@"Content-Length: %lu\r\n", $contentLength]];
    [headers appendString:@"\r\n"];
    
    [self write: [headers UTF8String] length: [headers lengthOfBytesUsingEncoding:NSUTF8StringEncoding]];
}

- (void) kill:(NSString*) message {
    [self __addNetworkingTask:^{
        #pragma clang diagnostic push
        #pragma clang diagnostic ignored "-Warc-retain-cycles"
        /*
            The block is stored temporary and removed when processed later,
            thus retain cycles should be a non-issue here.
         */
        if ([self isClosed]) {
            return;
        }
        
        [self $kill: message];
        #pragma clang diagnostic pop
    }];
}

- (NSString*) getStatusText:(NSUInteger) status {
    switch (status) {
        case NBSFuseAPIResponseStatusOk:
            return @"OK";
        case NBSFuseAPIResponseStatusError:
            return @"Bad Request";
        case NBSFuseAPIResponseStatusInternalError:
            return @"Internal Error";
        default:
            return @"Unknown";
    }
}

- (void) pushData:(NSData*) data {
    if (!$hasSentHeaders) {
        NSLog(@"Cannot send data before headers are sent. Must call finishHeaders first!");
        // TODO: Raise exception somehow
        return;
    }
    
    [self write: [data bytes] length:[data length]];
}

- (void) didFinish {
    [self __addNetworkingTask:^{
        #pragma clang diagnostic push
        #pragma clang diagnostic ignored "-Warc-retain-cycles"
        /*
            The block is stored temporary and removed when processed later,
            thus retain cycles should be a non-issue here.
         */
        self->$isClosed = true;
        NSLog(@"Closing for %d", self->$client);
        int result = shutdown(self->$client, SHUT_RDWR);
        if (result == -1) {
            NSLog(@"Socket shudown error: %d", errno);
        }
        #pragma clang diagnostic pop
    }];
}

- (void) didInternalError {
    [self setStatus:NBSFuseAPIResponseStatusInternalError];
    [self setContentType:@"text/plain"];
    NSString* msg = @"Internal Error. See native logs for more details";
    [self setContentLength:[msg length]];
    [self didFinishHeaders];
    [self pushData: [msg dataUsingEncoding:NSUTF8StringEncoding]];
    [self didFinish];
}

- (void) finishHeaders:(NSUInteger) status withContentType:(NSString*) contentType withContentLength:(NSUInteger) contentLength {
    [self setStatus:status];
    [self setContentType:contentType];
    [self setContentLength:contentLength];
    [self didFinishHeaders];
}

- (void) sendData:(NSData*) data {
    [self finishHeaders:NBSFuseAPIResponseStatusOk withContentType:@"application/octet-stream" withContentLength: data.length];
    [self pushData: data];
    [self didFinish];
}

- (void) sendData:(NSData*) data withType:(NSString*) type {
    [self finishHeaders:NBSFuseAPIResponseStatusOk withContentType:type withContentLength: data.length];
    [self pushData: data];
    [self didFinish];
}

- (void) sendJSON:(NSDictionary*) data {
    NSError* serializationError;
    NSData* serialized = [NSJSONSerialization dataWithJSONObject:data options:NSJSONWritingPrettyPrinted error:&serializationError];
    if (serializationError != nil) {
        NSLog(@"Error domain: %@", serializationError.domain);
        NSLog(@"Error code: %ld", (long)serializationError.code);
        NSLog(@"Error description: %@", serializationError.localizedDescription);
        
        if (serializationError.localizedFailureReason) {
            NSLog(@"Failure reason: %@", serializationError.localizedFailureReason);
        }
        
        if (serializationError.localizedRecoverySuggestion) {
            NSLog(@"Recovery suggestion: %@", serializationError.localizedRecoverySuggestion);
        }
        
        NSLog(@"Error user info: %@", serializationError.userInfo);
        [self didInternalError];
        return;
    }
    [self finishHeaders:NBSFuseAPIResponseStatusOk withContentType:@"application/json" withContentLength: serialized.length];
    [self pushData:serialized];
    [self didFinish];
}

- (void) sendString:(NSString*) data {
    [self finishHeaders:NBSFuseAPIResponseStatusOk withContentType:@"text/plain" withContentLength:[data length]];
    [self pushData: [data dataUsingEncoding:NSUTF8StringEncoding]];
    [self didFinish];
}

- (void) sendNoContent {
    [self finishHeaders:NBSFuseAPIResponseStatusOk withContentType:@"text/plain" withContentLength:0];
    [self didFinish];
}

- (void) sendError:(NBSFuseError*) error {
    NSError* serializationError = nil;
    NSString* data = [error serialize:serializationError];
    if (serializationError != nil) {
        NSLog(@"Error domain: %@", serializationError.domain);
        NSLog(@"Error code: %ld", (long)serializationError.code);
        NSLog(@"Error description: %@", serializationError.localizedDescription);
        
        if (serializationError.localizedFailureReason) {
            NSLog(@"Failure reason: %@", serializationError.localizedFailureReason);
        }
        
        if (serializationError.localizedRecoverySuggestion) {
            NSLog(@"Recovery suggestion: %@", serializationError.localizedRecoverySuggestion);
        }
        
        NSLog(@"Error user info: %@", serializationError.userInfo);
        [self didInternalError];
        return;
    }
    
    [self finishHeaders:NBSFuseAPIResponseStatusError withContentType:@"application/json" withContentLength:[data length]];
    [self pushData: [data dataUsingEncoding:NSUTF8StringEncoding]];
    [self didFinish];
}

@end
