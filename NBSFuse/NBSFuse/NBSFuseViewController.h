
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

#ifndef NBSFuseViewController_h
#define NBSFuseViewController_h

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <WebKit/WebKit.h>
#import <NBSFuse/NBSFuseWebviewUIDelegation.h>

@class NBSFuseContext;

@interface NBSFuseViewController: UIViewController <WKScriptMessageHandlerWithReply> {
    @private
    NBSFuseContext* $context;
    WKWebView* $webview;
    NBSFuseWebviewUIDelegation* $webviewUIDelegation;
}

- (NBSFuseContext*) getContext;

//- (instancetype) init NS_DESIGNATED_INITIALIZER;
//- (instancetype) initWithCoder:(NSCoder*) coder NS_DESIGNATED_INITIALIZER;
//- (instancetype) initWithNibName:(NSString*) nibNameOrNil bundle:(NSBundle*) nibBundleOrNil;
//- (instancetype) init:(NBSFuseContext*) context NS_DESIGNATED_INITIALIZER;

- (WKWebView*) getWebview;

@end

#endif
