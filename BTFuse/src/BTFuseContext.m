
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
#import <BTFuseSchemeHandler.h>
#import <BTFuse/BTFusePlugin.h>
#import <BTFuseAPIRouter.h>
#import <BTFuse/BTFuseAPIPacket.h>
#import <BTFuse/BTFuseAPIResponse.h>
#import <BTFuse/BTFuseRuntime.h>
#import <BTFuse/BTFuseViewController.h>
#import <BTFuse/BTFuseAPIServer.h>
#import <BTFuse/BTFuse.h>

@implementation BTFuseContext {
    NSMutableDictionary<NSString*, BTFusePlugin*>* $pluginMap;
    BTFuseAPIRouter* $apiRouter;
    __weak BTFuseViewController* $viewController;
    BTFuseAPIResponseFactory* $responseFactory;
    BTFuseLogger* $logger;
    BTFuseAPIServer* $apiServer;
}

- (instancetype) init:(BTFuseViewController*) controller {
    self = [super init];
    
    $logger = [[BTFuseLogger alloc] init: self];
    
    NSBundle* bundle = [NSBundle bundleForClass: [BTFuseContext class]];
    NSString* version = [bundle objectForInfoDictionaryKey: @"CFBundleShortVersionString"];
    NSString* build = [bundle objectForInfoDictionaryKey: @"CFBundleVersion"];
    [$logger info:@"Fuse %@ (%@)", version, build];
    
    $apiServer = [[BTFuseAPIServer alloc] init: self];
    
    $responseFactory = [[BTFuseAPIResponseFactory alloc] init];
    $apiRouter = [[BTFuseAPIRouter alloc] init: self];
    $pluginMap = [[NSMutableDictionary alloc] init];
    $viewController = controller;
    
    [self registerPlugin:[[BTFuseRuntime alloc] init: self]];
    
    return self;
}

- (BTFuseViewController*) getViewController {
    return $viewController;
}

- (void) execCallback:(NSString*) callbackID withData:(NSString*) data {
    dispatch_async(dispatch_get_main_queue(), ^{
        NSString* escapedData = [[data stringByReplacingOccurrencesOfString:@"\"" withString:@"\\\""] stringByReplacingOccurrencesOfString:@"\n" withString:@"\\n"];
        NSString* js = [[NSString alloc] initWithFormat:@"window.__btfuse_doCallback(\"%@\",\"%@\");", callbackID, escapedData];
        WKWebView* webview = [self->$viewController getWebview];
        [webview evaluateJavaScript:js completionHandler:nil];
    });
}

- (void) execCallback:(NSString*) callbackID {
    dispatch_async(dispatch_get_main_queue(), ^{
        NSString* js = [[NSString alloc] initWithFormat:@"window.__btfuse_doCallback(\"%@\");", callbackID];
        WKWebView* webview = [self->$viewController getWebview];
        [webview evaluateJavaScript:js completionHandler:nil];
    });
}

- (WKWebView*) getWebview {
    return [$viewController getWebview];
}

- (BTFuseAPIRouter*) getAPIRouter {
    return $apiRouter;
}

- (void) registerPlugin:(BTFusePlugin *)plugin {
    if ([$pluginMap objectForKey:[plugin getID]] != nil) {
        NSLog(@"A plugin is already registered for %@", [plugin getID]);
        return;
    }
    
    [$pluginMap setObject:plugin forKey:[plugin getID]];
}

- (BTFusePlugin*) getPlugin:(NSString*)pluginID {
    return [$pluginMap objectForKey:pluginID];
}

- (nonnull BTFuseAPIResponseFactory*) getResponseFactory {
    return $responseFactory;
}

- (void) setResponseFactory:(nonnull BTFuseAPIResponseFactory*) factory {
    $responseFactory = factory;
}

- (int) getAPIPort {
    return [$apiServer getPort];
}

- (NSString*) getAPISecret {
    return [$apiServer getSecret];
}

- (BTFuseLogger*) getLogger {
    return $logger;
}

@end
