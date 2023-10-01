
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
#import <XCTest/XCTest.h>
#import <NBSFuse/NBSFuse.h>
#import <NBSFuseTestTools/NBSFuseTestTools.h>

@interface NBSFuseAPITests : XCTestCase {
    NBSFuseTestViewController* $viewController;
    NBSFuseTestAPIClientBuilder* $apiBuilder;
}

@end

@implementation NBSFuseAPITests

- (void) setUp {
    $viewController = [[NBSFuseTestViewController alloc] init];
    [$viewController loadViewIfNeeded];
    
    NBSFuseContext* context = [$viewController getContext];
    
    $apiBuilder = [[NBSFuseTestAPIClientBuilder alloc] init];
    
    $apiBuilder.apiPort = @([context getAPIPort]);
    $apiBuilder.apiSecret = [context getAPISecret];
    $apiBuilder.pluginID = @"echo";
    $apiBuilder.contentType = @"text/plain";
}

- (void) tearDown {
    $viewController = nil;
}

- (void) testSimpleEchoRequest {
    $apiBuilder.endpoint = @"echo";
    $apiBuilder.data = [@"Hello Test!" dataUsingEncoding:NSUTF8StringEncoding];
    NBSFuseTestAPIClient* client = [$apiBuilder build];
    
    XCTestExpectation* expectation = [self expectationWithDescription:@"testSimpleEchoRequest"];
    
    [client execute:^(NSError * _Nullable error, NBSFuseTestAPIClientResponse * _Nullable response) {
        XCTAssertNil(error, @"Error should be nil");
        
        NSString* payload = [[NSString alloc] initWithData:response.data encoding:NSUTF8StringEncoding];
        XCTAssertTrue([payload isEqualToString:@"Hello Test!"], @"Payload should echo input");
        
        [expectation fulfill];
    }];
    
    [self waitForExpectationsWithTimeout:30.0 handler:nil];
}

- (void) testThreadedRequest {
    $apiBuilder.endpoint = @"threadtest";
    $apiBuilder.data = [@"Hello Test!" dataUsingEncoding:NSUTF8StringEncoding];
    NBSFuseTestAPIClient* client = [$apiBuilder build];
    
    XCTestExpectation* expectation = [self expectationWithDescription:@"testThreadedRequest"];
    
    [client execute:^(NSError * _Nullable error, NBSFuseTestAPIClientResponse * _Nullable response) {
        XCTAssertNil(error, @"Error should be nil");
        
        NSString* payload = [[NSString alloc] initWithData:response.data encoding:NSUTF8StringEncoding];
        XCTAssertTrue([payload isEqualToString:@"Hello Test!"], @"Payload should echo input");
        
        [expectation fulfill];
    }];
    
    [self waitForExpectationsWithTimeout:30.0 handler:nil];
}

//- (void) testShouldHaveContext {
//    NBSFuseContext* context = [$viewController getContext];
//    XCTAssert(context != nil);
//}
//
//- (void) testShouldHaveWebview {
//    WKWebView* webview = [$viewController getWebview];
//    XCTAssert(webview != nil);
//}

@end
