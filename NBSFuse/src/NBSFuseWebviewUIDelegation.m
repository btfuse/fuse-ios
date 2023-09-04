//
//  NBSFuseWebviewUIDelegation.m
//  NBSFuse
//
//  Created by Norman Breau on 2023-09-04.
//

#import <Foundation/Foundation.h>
#import <NBSFuseWebviewUIDelegation.h>
#import <NBSFuse/NBSFuseLocalization.h>

@implementation NBSFuseWebviewUIDelegation

- (void)    webView:(WKWebView*) webView
            runJavaScriptAlertPanelWithMessage:(NSString*) message
            initiatedByFrame:(WKFrameInfo*) frame
            completionHandler:(void (^)(void)) completionHandler
{
    
    UIAlertController* alertController = [ UIAlertController
        alertControllerWithTitle: nil
        message: message
        preferredStyle: UIAlertControllerStyleAlert
    ];
    
    [
        alertController
        addAction: [
            UIAlertAction
            actionWithTitle: [NBSFuseLocalization lookup:@"FUSE_DIALOG_OK_BUTTON_LABEL"]
            style: UIAlertActionStyleDefault
            handler: ^(UIAlertAction * _Nonnull action) {
                completionHandler();
            }
        ]
    ];
    
    [self presentViewController: alertController animated: true completion: nil];
}

- (void)    webView:(WKWebView*) webView
            runJavaScriptConfirmPanelWithMessage:(NSString*) message
            initiatedByFrame:(WKFrameInfo*) frame
            completionHandler:(void (^)(BOOL)) completionHandler
{
    UIAlertController* alertController = [
        UIAlertController
        alertControllerWithTitle: nil
        message: message
        preferredStyle: UIAlertControllerStyleAlert
    ];
    
    [
        alertController
        addAction: [
            UIAlertAction
            actionWithTitle: [NBSFuseLocalization lookup:@"FUSE_DIALOG_CANCEL_BUTTON_LABEL"]
            style: UIAlertActionStyleDefault
            handler: ^(UIAlertAction* _Nonnull action) {
                completionHandler(false);
            }
        ]
    ];
    
    [
        alertController
        addAction: [
            UIAlertAction
            actionWithTitle: [NBSFuseLocalization lookup:@"FUSE_DIALOG_OK_BUTTON_LABEL"]
            style: UIAlertActionStyleDefault
            handler: ^(UIAlertAction* _Nonnull action) {
                completionHandler(true);
            }
        ]
    ];
    
    [self presentViewController:alertController animated:YES completion:nil];
}

- (void)    webView:(WKWebView*) webView
            runJavaScriptTextInputPanelWithPrompt:(NSString*) prompt
            defaultText:(NSString*) defaultText
            initiatedByFrame:(WKFrameInfo*) frame
            completionHandler:(void (^)(NSString* _Nullable)) completionHandler
{
    UIAlertController* alertController = [
        UIAlertController alertControllerWithTitle: nil
        message: prompt
        preferredStyle: UIAlertControllerStyleAlert
    ];
    
    [
        alertController
        addTextFieldWithConfigurationHandler:^(UITextField* _Nonnull textField) {
            textField.text = defaultText;
        }
    ];
    
    [
        alertController
        addAction: [
            UIAlertAction
            actionWithTitle: [NBSFuseLocalization lookup:@"FUSE_DIALOG_CANCEL_BUTTON_LABEL"]
            style: UIAlertActionStyleDefault
            handler: ^(UIAlertAction * _Nonnull action) {
                completionHandler(nil);
            }
        ]
    ];
    
    [
        alertController
            addAction: [
                UIAlertAction
                actionWithTitle: [NBSFuseLocalization lookup:@"FUSE_DIALOG_OK_BUTTON_LABEL"]
                style: UIAlertActionStyleDefault
                handler: ^(UIAlertAction * _Nonnull action) {
                    completionHandler(alertController.textFields.firstObject.text);
                }
            ]
    ];
    
    [self presentViewController: alertController animated: true completion: nil];
}

@end
