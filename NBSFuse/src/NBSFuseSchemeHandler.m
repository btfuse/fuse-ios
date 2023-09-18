
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
#import <NBSFuse/NBSFuseContext.h>
#import <NBSFuse/NBSFusePlugin.h>
#import <NBSFuseSchemeHandler.h>
#import <NBSFuse/NBSFuseAPIRouter.h>
#import <NBSFuse/NBSFuseAPIPacket.h>
#import <NBSFuse/NBSFuseAPIResponse.h>
#import <MobileCoreServices/MobileCoreServices.h>

NSString* const SCHEME = @"nbsfuse";
NSString* const HOST = @"localhost";

@implementation NBSFuseSchemeHandler

- (instancetype) init:(NBSFuseContext*) context {
    self = [super init];
    
    $context = context;
    
    return self;
}

- (NBSFuseContext*) getContext {
    return $context;
}

- (void)webView:(WKWebView*)webView startURLSchemeTask:(id<WKURLSchemeTask>)urlSchemeTask {
    NSURLRequest* request = urlSchemeTask.request;
    NSURL* requestURL = request.URL;
    NSString* scheme = requestURL.scheme;
    
    if (![scheme isEqualToString: SCHEME]) {
        [self sendErrorResponseWithStatusCode:404 toURLSchemeTask:urlSchemeTask];
        return;
    }
    
    NSString* path = requestURL.path;
    
    if (![requestURL.host isEqualToString: HOST]) {
        [self sendErrorResponseWithStatusCode:404 toURLSchemeTask:urlSchemeTask];
        return;
    }
    
    NSLog(@"Scheme Path: %@", path);
    
    NSURL* route = [NSURL fileURLWithPath: path];
    NSLog(@"break");
    
    NSString* routeService = route.pathComponents[1];
    
    if ([routeService isEqualToString:@"assets"]) {
        NSString* bundlePath = [[NSBundle mainBundle] resourcePath];
        NSString* assetPath = [bundlePath stringByAppendingPathComponent:path];
        NSData* content = [NSData dataWithContentsOfFile:assetPath];
        
        NSString* fileExtension = [requestURL pathExtension];
        NSString* UTI = (__bridge_transfer NSString *)UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension, (__bridge CFStringRef)fileExtension, NULL);
        NSString* contentType = (__bridge_transfer NSString *)UTTypeCopyPreferredTagWithClass((__bridge CFStringRef)UTI, kUTTagClassMIMEType);
        
        if (content) {
            NSURLResponse* response = [[NSURLResponse alloc] initWithURL:requestURL MIMEType: contentType expectedContentLength:content.length textEncodingName:@"utf-8"];
            [urlSchemeTask didReceiveResponse: response];
            [urlSchemeTask didReceiveData: content];
            [urlSchemeTask didFinish];
        }
        else {
            [self sendErrorResponseWithStatusCode:404 toURLSchemeTask:urlSchemeTask];
        }
    }
    else {
        NSLog(@"Unknown Route Service: %@", routeService);
    }
}

- (void)webView:(nonnull WKWebView *)webView stopURLSchemeTask:(nonnull id<WKURLSchemeTask>)urlSchemeTask {
    // TODO: Figure out how to properly handle this delegation
}

- (void)sendErrorResponseWithStatusCode:(NSInteger)statusCode toURLSchemeTask:(id<WKURLSchemeTask>)urlSchemeTask {
    // Define the HTTP status code and the corresponding status text
    NSDictionary *statusCodeTexts = @{
        @(200): @"OK",
        @(404): @"Not Found",
        // Add more status codes and texts as needed
    };

    // Get the status text corresponding to the status code
    NSString *statusText = statusCodeTexts[@(statusCode)];

    // Construct the error response
    NSString *errorHTML = [NSString stringWithFormat:@"<html><body><h1>%ld %@</h1></body></html>", (long)statusCode, statusText];
    NSData *errorData = [errorHTML dataUsingEncoding:NSUTF8StringEncoding];

    // Create the HTTP response
    NSHTTPURLResponse *response = [[NSHTTPURLResponse alloc] initWithURL:urlSchemeTask.request.URL statusCode:statusCode HTTPVersion:@"HTTP/1.1" headerFields:nil];

    // Send the response
    [urlSchemeTask didReceiveResponse:response];
    [urlSchemeTask didReceiveData:errorData];
    [urlSchemeTask didFinish];
}

@end
