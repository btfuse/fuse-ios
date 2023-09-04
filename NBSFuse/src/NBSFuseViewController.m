
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

@implementation NBSFuseViewController

- (instancetype) init:(NBSFuseContext*) context {
    self = [super init];
    
    self.$context = context;
    
    self.$webviewUIDelegation = [[NBSFuseWebviewUIDelegation alloc] init];
    
    WKWebViewConfiguration* configuration = [[WKWebViewConfiguration alloc] init];
    
    //TODO: pass the configuration object to a overridable method to give a chance for application-level configuration
    [configuration setURLSchemeHandler: [
        [NBSFuseSchemeHandler alloc] init: context]
        forURLScheme: @"nbsfuse"
    ];
    
    self.$webview = [[WKWebView alloc] initWithFrame: CGRectZero configuration: configuration];
    self.$webview.UIDelegate = self.$webviewUIDelegation;
    
    return self;
}

- (WKWebView*) getWebview {
    return self.$webview;
}

- (void) viewDidLoad {
    [super viewDidLoad];
    
    [self addChildViewController: self.$webviewUIDelegation];
    [self.view addSubview: self.$webviewUIDelegation.view];
    
    // Calculate or determine the desired frame
    CGRect webviewFrame = CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height);
    
    // Set the frame for the WKWebView
    self.$webview.frame = webviewFrame;
    
    // Add the WKWebView as a subview
    [self.view addSubview:self.$webview];
    
    NSURL* url = [NSURL URLWithString:@"nbsfuse://localhost/assets/index.html"];
    NSURLRequest* request = [NSURLRequest requestWithURL:url];
    [self.$webview loadRequest:request];
}

@end
