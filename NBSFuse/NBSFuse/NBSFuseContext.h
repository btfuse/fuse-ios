
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

#ifndef NBSFuseContext_H
#define NBSFuseContext_H

#import <Foundation/Foundation.h>
#import <WebKit/WebKit.h>
#import <NBSFuse/NBSFuseAPIResponseFactory.h>

@class NBSFuseViewController;
@class NBSFusePlugin;
@class NBSFuseAPIRouter;
@class NBSFuseLogger;

@interface NBSFuseContext: NSObject {
    @private
    NSMutableDictionary<NSString*, NBSFusePlugin*>* $pluginMap;
    NBSFuseAPIRouter* $apiRouter;
    __weak NBSFuseViewController* $viewController;
    NBSFuseAPIResponseFactory* $responseFactory;
    NBSFuseLogger* $logger;
}

- (nonnull instancetype) init NS_UNAVAILABLE;
- (nonnull instancetype) init:(nonnull NBSFuseViewController*) controller NS_DESIGNATED_INITIALIZER;
- (nonnull NBSFuseAPIResponseFactory*) getResponseFactory;
- (void) setResponseFactory:(nonnull NBSFuseAPIResponseFactory*) factory;
- (nonnull WKWebView*) getWebview;
- (nonnull NBSFuseViewController*) getViewController;
- (void) registerPlugin:(nonnull NBSFusePlugin*)plugin;
- (nonnull NBSFusePlugin*) getPlugin:(nonnull NSString*)pluginID;
- (nonnull NBSFuseAPIRouter*) getAPIRouter;
- (void) execCallback:(nonnull NSString*) callbackID withData:(nonnull NSString*) data;
- (void) execCallback:(nonnull NSString*) callbackID;
- (int) getAPIPort;
- (nonnull NSString*) getAPISecret;
- (nonnull NBSFuseLogger*) getLogger;

@end

#endif
