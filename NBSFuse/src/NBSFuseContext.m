
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

@implementation NBSFuseContext

- (instancetype)init {
    self = [super init];
    
    self.$apiRouter = [[NBSFuseAPIRouter alloc] init: self];
    self.$pluginMap = [[NSMutableDictionary alloc] init];
    self.$viewController = [[NBSFuseViewController alloc] init: self];
    
//    WKWebViewConfiguration* configuration = [[WKWebViewConfiguration alloc] init];
//
//    //TODO: pass the configuration object to a overridable method to give a chance for application-level configuration
//    [configuration setURLSchemeHandler:[[NBSFuseSchemeHandler alloc] init: self] forURLScheme: @"nbsfuse"];
//
//    self.$webview = [[WKWebView alloc] initWithFrame:view.bounds configuration:configuration];
//    self.$webview.UIDelegate = self.$webviewUIDelegation;
//
//    [view addSubview: self.$webview];
    
    [self registerPlugin:[[NBSFuseRuntime alloc] init: self]];
    
//    NSURL* url = [NSURL URLWithString:@"nbsfuse://localhost/assets/index.html"];
//    NSURLRequest* request = [NSURLRequest requestWithURL:url];
//    [self.$webview loadRequest:request];
    
    return self;
}

- (NBSFuseViewController*) getViewController {
    return self.$viewController;
}

- (void) execCallback:(NSString*) callbackID withData:(NSString*) data {
    NSString* js = [[NSString alloc] initWithFormat:@"window.__nbsfuse_doCallback(%@,%@);", callbackID, data];
    [self.$webview evaluateJavaScript:js completionHandler:nil];
}

- (WKWebView*)getWebview {
    return self.$webview;
}

- (NBSFuseAPIRouter*) getAPIRouter {
    return self.$apiRouter;
}

- (void) registerPlugin:(NBSFusePlugin *)plugin {
    if ([self.$pluginMap objectForKey:[plugin getID]] != nil) {
        NSLog(@"A plugin is already registered for %@", [plugin getID]);
        return;
    }
    
    [self.$pluginMap setObject:plugin forKey:[plugin getID]];
}

- (NBSFusePlugin*) getPlugin:(NSString*)pluginID {
    return [self.$pluginMap objectForKey:pluginID];
}

@end
