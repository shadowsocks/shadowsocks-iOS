//
//  CKHTTPConnection.h
//  Connection
//
//  Created by Mike on 17/03/2009.
//  Copyright 2009 Karelia Software. All rights reserved.
//
//  Originally from ConnectionKit 2.0 branch; source at:
//  http://www.opensource.utr-software.com/source/connection/branches/2.0/CKHTTPConnection.h
//  (CKHTTPConnection.m last updated rev 1242, 2009-06-16 09:40:21 -0700, by mabdullah)
//  
//  Under Modified BSD License, as per description at
//  http://www.opensource.utr-software.com/


//  A sort of NSURLConnection-lite class. Deals purely with HTTP and is not multithreaded
//  internally. Adds the ability to track upload progress.


#import <Foundation/Foundation.h>


@protocol CKHTTPConnectionDelegate;
@class CKHTTPAuthenticationChallenge;


@interface CKHTTPConnection : NSObject
{
    @private
    __weak id <CKHTTPConnectionDelegate>   _delegate;       // weak ref
    
    CFHTTPMessageRef       _HTTPRequest;
    NSInputStream                   *_HTTPStream;
    BOOL                            _haveReceivedResponse;
    CKHTTPAuthenticationChallenge   *_authenticationChallenge;
    NSInteger                       _authenticationAttempts;
}

+ (CKHTTPConnection *)connectionWithRequest:(NSURLRequest *)request delegate:(id <CKHTTPConnectionDelegate>)delegate;

/*  Any caching instructions will be ignored
 */
- (id)initWithRequest:(NSURLRequest *)request delegate:(id <CKHTTPConnectionDelegate>)delegate;
- (void)cancel;

- (NSUInteger)lengthOfDataSent;

@end


@protocol CKHTTPConnectionDelegate  // Formal protocol for now

- (void)HTTPConnection:(CKHTTPConnection *)connection didReceiveAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge;
- (void)HTTPConnection:(CKHTTPConnection *)connection didCancelAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge;

- (void)HTTPConnection:(CKHTTPConnection *)connection didReceiveResponse:(NSHTTPURLResponse *)response;
- (void)HTTPConnection:(CKHTTPConnection *)connection didReceiveData:(NSData *)data;

- (void)HTTPConnectionDidFinishLoading:(CKHTTPConnection *)connection;
- (void)HTTPConnection:(CKHTTPConnection *)connection didFailWithError:(NSError *)error;

@end


@interface NSURLRequest (CKHTTPURLRequest)
- (CFHTTPMessageRef)makeHTTPMessage;
@end


@interface NSHTTPURLResponse (CKHTTPConnectionAdditions)
+ (NSHTTPURLResponse *)responseWithURL:(NSURL *)URL HTTPMessage:(CFHTTPMessageRef)message;
@end

