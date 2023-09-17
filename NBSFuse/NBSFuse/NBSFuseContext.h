
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

@class NBSFuseViewController;
@class NBSFusePlugin;
@class NBSFuseAPIRouter;

@interface NBSFuseContext: NSObject {
    @private
    NSMutableDictionary<NSString*, NBSFusePlugin*>* $pluginMap;
    NBSFuseAPIRouter* $apiRouter;
    __weak NBSFuseViewController* $viewController;
}

- (instancetype) init NS_UNAVAILABLE;
- (instancetype) init:(NBSFuseViewController*) controller NS_DESIGNATED_INITIALIZER;
- (WKWebView*) getWebview;
- (NBSFuseViewController*) getViewController;
- (void) registerPlugin:(NBSFusePlugin*)plugin;
- (NBSFusePlugin*) getPlugin:(NSString*)pluginID;
- (NBSFuseAPIRouter*) getAPIRouter;
- (void) execCallback:(NSString*) callbackID withData:(NSString*) data;
- (void) execCallback:(NSString*) callbackID;

@end

#endif
