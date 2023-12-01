
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
#import <BTFuse/BTFuseContext.h>
#import <BTFuse/BTFuseAPIResponse.h>
#import <BTFuse/BTFuseLogger.h>
#include <sys/socket.h>
#include <pthread.h>

typedef void (^BTFuseAPIResponse_TaskBlock)(void);

@implementation BTFuseAPIResponse {
    pthread_mutex_t $workerMutex;
    pthread_t $workerThread;
    NSMutableArray<BTFuseAPIResponse_TaskBlock>* $workerQueue;
    BTFuseAPIClient* $client;
    bool $hasSentHeaders;
    bool $isClosed;
    BTFuseContext* $context;
    NSUInteger $status;
    NSUInteger $contentLength;
    NSString* $contentType;
    dispatch_queue_t $networkQueue;
    uint64_t $startTime;
}

void* $BTFuseAPIResponse_processTask(void* pdata) {
    BTFuseAPIResponse* res = (__bridge BTFuseAPIResponse*)pdata;
    
    pthread_mutex_t* workerMutex = [res __getWorkerMutex];
    
    while (true) {
        if (![res isClosed]) {
            pthread_mutex_lock(workerMutex);
        }
        else {
            break;
        }
        
        while ([res __hasTaskAvailable]) {
            BTFuseAPIResponse_TaskBlock task = [res __getNextTask];
            task();
        }
    }
    
    return NULL;
}

- (instancetype) init:(BTFuseContext*) context client:(BTFuseAPIClient*) client {
    self = [super init];
    
    $startTime = mach_absolute_time();
    
    $context = context;
    BTFuseLogger* logger = [$context getLogger];
    
    $client = client;
    if (pthread_mutex_init(&$workerMutex, NULL) != 0) {
        [logger error:@"Worker Mutex Init Failure"];
        return nil;
    }
    
    $workerQueue = [[NSMutableArray alloc] init];
    $isClosed = false;
    $hasSentHeaders = false;
    $status = BTFuseAPIResponseStatusOk;
    $contentLength = 0;
    $contentType = @"application/octet-stream";
    
    pthread_create(&self->$workerThread, NULL, &$BTFuseAPIResponse_processTask, (__bridge void *)(self));
    
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

- (void) __addNetworkingTask:(BTFuseAPIResponse_TaskBlock) task {
    @synchronized ($workerQueue) {
        [$workerQueue addObject:task];
        pthread_mutex_unlock(&$workerMutex);
    }
}

- (BTFuseAPIResponse_TaskBlock) __getNextTask {
    @synchronized ($workerQueue) {
        BTFuseAPIResponse_TaskBlock task = [$workerQueue firstObject];
        [$workerQueue removeObjectAtIndex: 0];
        return task;
    }
}

- (void) $kill:(NSString*) message {
    if ($isClosed) {
        return;
    }
    
    $status = 0;
    
    BTFuseLogger* logger = [$context getLogger];
    [logger error: @"Killing %@ for reason: %@", [$client getID], message];
    
    $isClosed = true;
    [$client close];
//    close($client);
    [self $printEndTime];
}

- (void) $printEndTime {
    BTFuseLogger* logger = [$context getLogger];
    
    uint64_t elapsed = mach_absolute_time() - $startTime;
    mach_timebase_info_data_t timebase;
    kern_return_t kernResult = mach_timebase_info(&timebase);
    
    if (kernResult != KERN_SUCCESS) {
        [logger info:@"Response (Request %@ with status %lu. Time information not available.", [$client getID], $status];
        return;
    }
    
    double UNIT = 1e-9 * (double)timebase.numer / (double)timebase.denom;
    double elapsedSeconds = (double)elapsed * UNIT;
    
    [logger info:@"Response (Request %@) closed with status %lu in %fs", [$client getID], $status, elapsedSeconds];
}

- (ssize_t) $write:(const void*) data length:(size_t) length {
    NSData* nsdata = [[NSData alloc] initWithBytes: data length: length];
    return [$client write: nsdata];
//    return write($client, data, length);
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
    [headers appendString:[NSString stringWithFormat:@"Access-Control-Allow-Origin: %@\r\n", @"btfuse://localhost"]];
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
        case BTFuseAPIResponseStatusOk:
            return @"OK";
        case BTFuseAPIResponseStatusError:
            return @"Bad Request";
        case BTFuseAPIResponseStatusInternalError:
            return @"Internal Error";
        default:
            return @"Unknown";
    }
}

- (void) pushData:(NSData*) data {
    if (!$hasSentHeaders) {
        [self kill:@"Cannot send data before headers are sent. Must call finishHeaders first!"];
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
        [self->$client close];
//        shutdown(self->$client, SHUT_RDWR);
        #pragma clang diagnostic pop
        
        [self $printEndTime];
    }];
}

- (void) didInternalError {
    [self setStatus:BTFuseAPIResponseStatusInternalError];
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
    [self finishHeaders:BTFuseAPIResponseStatusOk withContentType:@"application/octet-stream" withContentLength: data.length];
    [self pushData: data];
    [self didFinish];
}

- (void) sendData:(NSData*) data withType:(NSString*) type {
    [self finishHeaders:BTFuseAPIResponseStatusOk withContentType:type withContentLength: data.length];
    [self pushData: data];
    [self didFinish];
}

- (void) sendJSON:(NSDictionary*) data {
    NSError* serializationError;
    NSData* serialized = [NSJSONSerialization dataWithJSONObject:data options:NSJSONWritingPrettyPrinted error:&serializationError];
    if (serializationError != nil) {
        BTFuseLogger* logger = [$context getLogger];
        
        [logger error:@"Error domain: %@", serializationError.domain];
        [logger error:@"Error code: %ld", (long)serializationError.code];
        [logger error:@"Error description: %@", serializationError.localizedDescription];
        
        if (serializationError.localizedFailureReason) {
            [logger error:@"Failure reason: %@", serializationError.localizedFailureReason];
        }
        
        if (serializationError.localizedRecoverySuggestion) {
            [logger error:@"Recovery suggestion: %@", serializationError.localizedRecoverySuggestion];
        }
        
        [logger error:@"Error user info: %@", serializationError.userInfo];
        [self didInternalError];
        return;
    }
    [self finishHeaders:BTFuseAPIResponseStatusOk withContentType:@"application/json" withContentLength: serialized.length];
    [self pushData:serialized];
    [self didFinish];
}

- (void) sendString:(NSString*) data {
    [self finishHeaders:BTFuseAPIResponseStatusOk withContentType:@"text/plain" withContentLength:[data length]];
    [self pushData: [data dataUsingEncoding:NSUTF8StringEncoding]];
    [self didFinish];
}

- (void) sendNoContent {
    [self finishHeaders:BTFuseAPIResponseStatusOk withContentType:@"text/plain" withContentLength:0];
    [self didFinish];
}

- (void) sendError:(BTFuseError*) error {
    NSError* serializationError = nil;
    NSString* data = [error serialize:serializationError];
    if (serializationError != nil) {
        BTFuseLogger* logger = [$context getLogger];
        [logger error:@"Error domain: %@", serializationError.domain];
        [logger error:@"Error code: %ld", (long)serializationError.code];
        [logger error:@"Error description: %@", serializationError.localizedDescription];
        
        if (serializationError.localizedFailureReason) {
            [logger error:@"Failure reason: %@", serializationError.localizedFailureReason];
        }
        
        if (serializationError.localizedRecoverySuggestion) {
            [logger error:@"Recovery suggestion: %@", serializationError.localizedRecoverySuggestion];
        }
        
        [logger error:@"Error user info: %@", serializationError.userInfo];
        [self didInternalError];
        return;
    }
    
    [self finishHeaders:BTFuseAPIResponseStatusError withContentType:@"application/json" withContentLength:[data length]];
    [self pushData: [data dataUsingEncoding:NSUTF8StringEncoding]];
    [self didFinish];
}

@end
