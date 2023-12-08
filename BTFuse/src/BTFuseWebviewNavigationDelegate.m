
/*
Copyright Breautek

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
#import <BTFuse/BTFuseWebviewNavigationDelegate.h>
#import <BTFuse/BTFuseContext.h>
#include <openssl/bio.h>
#include <openssl/x509.h>

@implementation BTFuseWebviewNavigationDelegate {
    __weak BTFuseContext* $context;
}

- (instancetype) init:(BTFuseContext*) context {
    self = [super init];
    
    $context = context;
    
    return self;
}

- (void) webView:(WKWebView*) webView
    didReceiveAuthenticationChallenge:(NSURLAuthenticationChallenge*) challenge
    completionHandler: (void (^)(NSURLSessionAuthChallengeDisposition, NSURLCredential* _Nullable)) completionHandler
{
    if (![challenge.protectionSpace.authenticationMethod isEqualToString:NSURLAuthenticationMethodServerTrust]) {
        completionHandler(NSURLSessionAuthChallengePerformDefaultHandling, nil);
        return;
    }
    
    NSURLProtectionSpace* protectionSpace = challenge.protectionSpace;
    
    // First we will do some basic checks, anything that isn't hitting our API server can be routed to the default handling.
    
    if (![protectionSpace.host isEqualToString: @"localhost" ]) {
        // not our API server, do the default
        completionHandler(NSURLSessionAuthChallengePerformDefaultHandling, nil);
        return;
    }
    
    if (![protectionSpace.protocol isEqualToString: @"https" ]) {
        // not our API server, do the default
        completionHandler(NSURLSessionAuthChallengePerformDefaultHandling, nil);
        return;
    }
    
    if (protectionSpace.port != [$context getAPIPort]) {
        completionHandler(NSURLSessionAuthChallengePerformDefaultHandling, nil);
        return;
    }
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        SecTrustRef serverTrust = challenge.protectionSpace.serverTrust;
        CFArrayRef certificates = SecTrustCopyCertificateChain(serverTrust);
        
        if (CFArrayGetCount(certificates) == 0) {
            completionHandler(NSURLSessionAuthChallengePerformDefaultHandling, nil);
            return;
        }
        
        SecCertificateRef certificate = (SecCertificateRef) CFArrayGetValueAtIndex(certificates, 0);
        
        // Apple lacks iOS APIs to read certificate information. APIs to pull OIDs from the certificate are,
        // unfortunately only available in MacOS SDK. So we will export the certificate data and bridge it to OpenSSL instead.
        CFDataRef certData = SecCertificateCopyData(certificate);
        if (certData == NULL) {
            completionHandler(NSURLSessionAuthChallengePerformDefaultHandling, nil);
            return;
        }
        
        CFIndex length = CFDataGetLength(certData);
        const uint8_t* bytes = CFDataGetBytePtr(certData);
        
        BIO* bio = BIO_new_mem_buf(bytes, (int) length);
        if (!bio) {
            completionHandler(NSURLSessionAuthChallengePerformDefaultHandling, nil);
            return;
        }
        
        X509* x509 = d2i_X509_bio(bio, NULL);
        if (!x509) {
            completionHandler(NSURLSessionAuthChallengePerformDefaultHandling, nil);
            return;
        }
        
        X509_NAME* subject = X509_get_subject_name(x509);
        int nameCount = X509_NAME_entry_count(subject);
        
        ASN1_OBJECT* uidFieldOid = OBJ_txt2obj("UID", 0);
        
        NSString* certUID = nil;
        
        for (int i = 0; i < nameCount; i++) {
            X509_NAME_ENTRY* entry = X509_NAME_get_entry(subject, i);
            ASN1_OBJECT* obj = X509_NAME_ENTRY_get_object(entry);
            ASN1_STRING* data = X509_NAME_ENTRY_get_data(entry);
            
            if (OBJ_cmp(obj, uidFieldOid) == 0) {
                const unsigned char* uidValue = ASN1_STRING_get0_data(data);
                certUID = [[NSString alloc] initWithCString: (const char*) uidValue encoding:NSUTF8StringEncoding];
                break;
            }
        }
        
        if (certUID == nil) {
            completionHandler(NSURLSessionAuthChallengePerformDefaultHandling, nil);
            return;
        }
        
        NSString* keyIdentifier = [self->$context getAPIKeyIdentifier];
        if ([keyIdentifier isEqualToString: certUID]) {
            NSURLCredential* credential = [NSURLCredential credentialForTrust:serverTrust];
            completionHandler(NSURLSessionAuthChallengeUseCredential, credential);
        }
        else {
            completionHandler(NSURLSessionAuthChallengePerformDefaultHandling, nil);
        }
    });
}

@end
