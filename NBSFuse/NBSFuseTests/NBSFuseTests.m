
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

#import <XCTest/XCTest.h>
#import <NBSFuse/NBSFuse.h>
#import <NBSFuseTestTools/NBSFuseTestTools.h>

@interface NBSFuseTests : XCTestCase {
    NBSFuseTestViewController* $viewController;
}
    
@end

@implementation NBSFuseTests

- (void)setUp {
    $viewController = [[NBSFuseTestViewController alloc] init];
    [$viewController loadViewIfNeeded];
}

- (void)tearDown {
    $viewController = nil;
}

- (void) testShouldHaveContext {
    NBSFuseContext* context = [$viewController getContext];
    XCTAssert(context != nil);
}

- (void) testShouldHaveWebview {
    WKWebView* webview = [$viewController getWebview];
    XCTAssert(webview != nil);
}

@end
