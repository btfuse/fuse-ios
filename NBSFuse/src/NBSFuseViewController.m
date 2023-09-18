
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
#import <NBSFuse/NBSFuseViewController.h>
#import <NBSFuse/NBSFuseSchemeHandler.h>
#import <NBSFuse/NBSFuseWebviewUIDelegation.h>
#import "NBSFuseAPIServer.h"

@interface NBSFuseViewController () {
    NBSFuseAPIServer* $apiServer;
}
@end

@implementation NBSFuseViewController

- (instancetype) init {
    self = [super init];
    $context = [[NBSFuseContext alloc] init: self];
    $apiServer = [[NBSFuseAPIServer alloc] init:$context];
    return self;
}

- (void) viewDidLoad {
    [super viewDidLoad];
    
    $webviewUIDelegation = [[NBSFuseWebviewUIDelegation alloc] init];
    
    WKWebViewConfiguration* configuration = [[WKWebViewConfiguration alloc] init];
    [configuration.userContentController addScriptMessageHandlerWithReply: self contentWorld: WKContentWorld.pageWorld name:@"getAPIPort"];
    [configuration.userContentController addScriptMessageHandlerWithReply: self contentWorld: WKContentWorld.pageWorld name:@"getAPISecret"];
    
    //TODO: pass the configuration object to a overridable method to give a chance for application-level configuration
    [configuration setURLSchemeHandler: [
        [NBSFuseSchemeHandler alloc] init: $context]
        forURLScheme: @"nbsfuse"
    ];
    
    $webview = [[WKWebView alloc] initWithFrame: CGRectZero configuration: configuration];
    $webview.UIDelegate = $webviewUIDelegation;
    
    [self addChildViewController: $webviewUIDelegation];
    [self.view addSubview: $webviewUIDelegation.view];
    
    // Calculate or determine the desired frame
    CGRect webviewFrame = CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height);
    
    // Set the frame for the WKWebView
    $webview.frame = webviewFrame;
    
    // Add the WKWebView as a subview
    [self.view addSubview:$webview];
    
    NSURL* url = [NSURL URLWithString:@"nbsfuse://localhost/assets/index.html"];
    NSURLRequest* request = [NSURLRequest requestWithURL:url];
    [$webview loadRequest:request];
}


- (WKWebView*) getWebview {
    return $webview;
}

- (NBSFuseContext*) getContext {
    return $context;
}

- (void)    userContentController:(WKUserContentController*) userContentController
            didReceiveScriptMessage:(WKScriptMessage*) message
            replyHandler:(void (^)(id _Nullable, NSString* _Nullable)) replyHandler
{
    if ([message.name isEqualToString:@"getAPIPort" ]) {
        int port = [$apiServer getPort];
        replyHandler([[NSNumber alloc] initWithInt:port], nil);
        return;
    }
    else if ([message.name isEqualToString:@"getAPISecret"]) {
        NSString* secret = [$apiServer getSecret];
        replyHandler(secret, nil);
        return;
    }
    
    replyHandler(nil, @"Unhandled Script");
}

@end
