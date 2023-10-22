
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
#import <BTFuse/BTFuseViewController.h>
#import <BTFuse/BTFuseSchemeHandler.h>
#import <BTFuse/BTFuseWebviewUIDelegation.h>
#import "BTFuseAPIServer.h"
#import <BTFuse/BTFuseLogger.h>
#import <BTFuse/BTFuseLoggerLevel.h>

@implementation BTFuseViewController {
    BTFuseContext* $context;
    WKWebView* $webview;
    BTFuseWebviewUIDelegation* $webviewUIDelegation;
}

- (instancetype) init {
    self = [super init];
    $context = [[BTFuseContext alloc] init: self];
    return self;
}

- (void) viewDidLoad {
    [super viewDidLoad];
    
    $webviewUIDelegation = [[BTFuseWebviewUIDelegation alloc] init];
    
    WKWebViewConfiguration* configuration = [[WKWebViewConfiguration alloc] init];
    [configuration.userContentController addScriptMessageHandlerWithReply: self contentWorld: WKContentWorld.pageWorld name:@"getAPIPort"];
    [configuration.userContentController addScriptMessageHandlerWithReply: self contentWorld: WKContentWorld.pageWorld name:@"getAPISecret"];
    [configuration.userContentController addScriptMessageHandler: self name:@"log"];
    [configuration.userContentController addScriptMessageHandler: self name:@"setLogCallback"];

    NSString* fuseBuildTag = @"Release";
    #ifdef DEBUG
        fuseBuildTag = @"Debug";
    #endif
    // TODO: Pull Version information somehow
    configuration.applicationNameForUserAgent = [NSString stringWithFormat:@"FuseRuntime (%@ %@ Build", @"0.0.0", fuseBuildTag];

    //TODO: pass the configuration object to a overridable method to give a chance for application-level configuration
    [configuration setURLSchemeHandler: [
        [BTFuseSchemeHandler alloc] init: $context]
        forURLScheme: @"BTfuse"
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
    
    NSURL* url = [NSURL URLWithString:@"BTfuse://localhost/assets/index.html"];
    NSURLRequest* request = [NSURLRequest requestWithURL:url];
    [$webview loadRequest:request];
}


- (WKWebView*) getWebview {
    return $webview;
}

- (BTFuseContext*) getContext {
    return $context;
}

- (void) userContentController:(WKUserContentController*) userContentController didReceiveScriptMessage:(WKScriptMessage*) message {
    if ([message.name isEqualToString:@"log"] /* && [message.body isKindOfClass:[NSString class]]*/) {
        if ([message.body isKindOfClass:[NSArray class]]) {
            NSArray* logArgs = message.body;
            if ([logArgs count] < 2) {
                NSLog(@"Received log from webview but with invalid arguments.");
            }
            
            BTFuseLoggerLevel level = [[logArgs objectAtIndex: 0] unsignedIntValue];
            NSString* levelLabel = BTFuseLoggerLevel_toString(level);
            NSString* content = [logArgs objectAtIndex: 1];
            
            NSLog(@"[%@]: %@", levelLabel, content);
        }
        else {
            NSLog(@"Received log from webview but with invalid arguments.");
        }
    }
    else if ([message.name isEqualToString:@"setLogCallback"]) {
        if ([message.body isKindOfClass:[NSString class]]) {
            NSString* callbackID = message.body;
            [[$context getLogger] setCallbackID: callbackID];
        }
    }
}

- (void)    userContentController:(WKUserContentController*) userContentController
            didReceiveScriptMessage:(WKScriptMessage*) message
            replyHandler:(void (^)(id _Nullable, NSString* _Nullable)) replyHandler
{
    if ([message.name isEqualToString:@"getAPIPort" ]) {
        int port = [$context getAPIPort];
        replyHandler([[NSNumber alloc] initWithInt:port], nil);
        return;
    }
    else if ([message.name isEqualToString:@"getAPISecret"]) {
        NSString* secret = [$context getAPISecret];
        replyHandler(secret, nil);
        return;
    }
    
    replyHandler(nil, @"Unhandled Script");
}

@end
