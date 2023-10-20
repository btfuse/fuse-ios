
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
#import <NBSFuseSchemeHandler.h>
#import <NBSFuse/NBSFusePlugin.h>
#import <NBSFuseAPIRouter.h>
#import <NBSFuse/NBSFuseAPIPacket.h>
#import <NBSFuse/NBSFuseAPIResponse.h>
#import <NBSFuse/NBSFuseRuntime.h>
#import <NBSFuse/NBSFuseViewController.h>
#import <NBSFuse/NBSFuseAPIServer.h>
#import <NBSFuse/NBSFuse.h>

@implementation NBSFuseContext {
    NSMutableDictionary<NSString*, NBSFusePlugin*>* $pluginMap;
    NBSFuseAPIRouter* $apiRouter;
    __weak NBSFuseViewController* $viewController;
    NBSFuseAPIResponseFactory* $responseFactory;
    NBSFuseLogger* $logger;
    NBSFuseAPIServer* $apiServer;
}

- (instancetype) init:(NBSFuseViewController*) controller {
    self = [super init];
    
    $logger = [[NBSFuseLogger alloc] init: self];
    
    NSBundle* bundle = [NSBundle bundleForClass: [NBSFuseContext class]];
    NSString* version = [bundle objectForInfoDictionaryKey: @"CFBundleShortVersionString"];
    NSString* build = [bundle objectForInfoDictionaryKey: @"CFBundleVersion"];
    [$logger info:@"Fuse %@ (%@)", version, build];
    
    $apiServer = [[NBSFuseAPIServer alloc] init: self];
    
    $responseFactory = [[NBSFuseAPIResponseFactory alloc] init];
    $apiRouter = [[NBSFuseAPIRouter alloc] init: self];
    $pluginMap = [[NSMutableDictionary alloc] init];
    $viewController = controller;
    
    [self registerPlugin:[[NBSFuseRuntime alloc] init: self]];
    
    return self;
}

- (NBSFuseViewController*) getViewController {
    return $viewController;
}

- (void) execCallback:(NSString*) callbackID withData:(NSString*) data {
    dispatch_async(dispatch_get_main_queue(), ^{
        NSString* escapedData = [[data stringByReplacingOccurrencesOfString:@"\"" withString:@"\\\""] stringByReplacingOccurrencesOfString:@"\n" withString:@"\\n"];
        NSString* js = [[NSString alloc] initWithFormat:@"window.__nbsfuse_doCallback(\"%@\",\"%@\");", callbackID, escapedData];
        WKWebView* webview = [self->$viewController getWebview];
        [webview evaluateJavaScript:js completionHandler:nil];
    });
}

- (void) execCallback:(NSString*) callbackID {
    dispatch_async(dispatch_get_main_queue(), ^{
        NSString* js = [[NSString alloc] initWithFormat:@"window.__nbsfuse_doCallback(\"%@\");", callbackID];
        WKWebView* webview = [self->$viewController getWebview];
        [webview evaluateJavaScript:js completionHandler:nil];
    });
}

- (WKWebView*) getWebview {
    return [$viewController getWebview];
}

- (NBSFuseAPIRouter*) getAPIRouter {
    return $apiRouter;
}

- (void) registerPlugin:(NBSFusePlugin *)plugin {
    if ([$pluginMap objectForKey:[plugin getID]] != nil) {
        NSLog(@"A plugin is already registered for %@", [plugin getID]);
        return;
    }
    
    [$pluginMap setObject:plugin forKey:[plugin getID]];
}

- (NBSFusePlugin*) getPlugin:(NSString*)pluginID {
    return [$pluginMap objectForKey:pluginID];
}

- (nonnull NBSFuseAPIResponseFactory*) getResponseFactory {
    return $responseFactory;
}

- (void) setResponseFactory:(nonnull NBSFuseAPIResponseFactory*) factory {
    $responseFactory = factory;
}

- (int) getAPIPort {
    return [$apiServer getPort];
}

- (NSString*) getAPISecret {
    return [$apiServer getSecret];
}

- (NBSFuseLogger*) getLogger {
    return $logger;
}

@end
