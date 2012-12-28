//
//  CKHTTPConnection.m
//  Connection
//
//  Created by Mike on 17/03/2009.
//  Copyright 2009 Karelia Software. All rights reserved.
//
//  Originally from ConnectionKit 2.0 branch; source at:
//  http://www.opensource.utr-software.com/source/connection/branches/2.0/CKHTTPConnection.m
//  (CKHTTPConnection.m last updated rev 1242, 2009-06-16 09:40:21 -0700, by mabdullah)
//  
//  Under Modified BSD License, as per description at
//  http://www.opensource.utr-software.com/
//

#import "CKHTTPConnection.h"
#import "AppDelegate.h"


// There is no public API for creating an NSHTTPURLResponse. The only way to create one then, is to
// have a private subclass that others treat like a standard NSHTTPURLResponse object. Framework
// code can instantiate a CKHTTPURLResponse object directly. Alternatively, there is a public
// convenience method +[NSHTTPURLResponse responseWithURL:HTTPMessage:]


@interface CKHTTPURLResponse : NSHTTPURLResponse
{
    @private
    NSInteger       _statusCode;
    NSDictionary    *_headerFields;
}

- (id)initWithURL:(NSURL *)URL HTTPMessage:(CFHTTPMessageRef)message;
@end


@interface CKHTTPAuthenticationChallenge : NSURLAuthenticationChallenge
{
    CFHTTPAuthenticationRef _HTTPAuthentication;
}

- (id)initWithResponse:(CFHTTPMessageRef)response
    proposedCredential:(NSURLCredential *)credential
  previousFailureCount:(NSInteger)failureCount
       failureResponse:(NSHTTPURLResponse *)URLResponse
                sender:(id <NSURLAuthenticationChallengeSender>)sender;

- (CFHTTPAuthenticationRef)CFHTTPAuthentication;

@end


@interface CKHTTPConnection ()
- (CFHTTPMessageRef)HTTPRequest;
- (NSInputStream *)HTTPStream;

- (void)start;
- (id <CKHTTPConnectionDelegate>)delegate;
@end


@interface CKHTTPConnection (Authentication) <NSURLAuthenticationChallengeSender>
- (CKHTTPAuthenticationChallenge *)currentAuthenticationChallenge;
@end


#pragma mark -


@implementation CKHTTPConnection

#pragma mark  Init & Dealloc

+ (CKHTTPConnection *)connectionWithRequest:(NSURLRequest *)request delegate:(id <CKHTTPConnectionDelegate>)delegate
{
    return [[self alloc] initWithRequest:request delegate:delegate];
}

- (id)initWithRequest:(NSURLRequest *)request delegate:(id <CKHTTPConnectionDelegate>)delegate;
{
    NSParameterAssert(request);
    
    if (self = [super init])
    {
        _delegate = delegate;
        
        // Kick off the connection
        _HTTPRequest = [request makeHTTPMessage];
        
        [self start];
    }
    
    return self;
}

- (void)dealloc
{
    CFRelease(_HTTPRequest);
}

#pragma mark Accessors

- (CFHTTPMessageRef)HTTPRequest { return _HTTPRequest; }

- (NSInputStream *)HTTPStream { return _HTTPStream; }

- (NSInputStream *)stream { return (NSInputStream *)[self HTTPStream]; }

- (id <CKHTTPConnectionDelegate>)delegate { return _delegate; }

/*  CFHTTPStream provides no callback API for upload progress, so clients must request it themselves.
 */
- (NSUInteger)lengthOfDataSent
{
    return [[[self stream]
             propertyForKey:(NSString *)kCFStreamPropertyHTTPRequestBytesWrittenCount]
            unsignedIntValue];
}

#pragma mark Status handling

- (void)start
{
    NSAssert(!_HTTPStream, @"Connection already started");
    
    _HTTPStream = (__bridge_transfer NSInputStream *)CFReadStreamCreateForHTTPRequest(NULL, [self HTTPRequest]);

    AppDelegate *appDelegate = [[UIApplication sharedApplication] delegate];

    // Ignore SSL errors for domains if user has explicitly said to "continue anyway"
    // (for self-signed certs)
    // Ignore SSL errors for .onion addresses because they will not have been
    // signed by known authorities. (They will be self-signed or signed by alternative roots
    // similar to CACert or they are actually the cert for the non-.onion version of that domain.)
    NSURL *URL = [_HTTPStream propertyForKey:(NSString *)kCFStreamPropertyHTTPFinalURL];
    if ([URL.absoluteString rangeOfString:@"https://"].location == 0) {
        Boolean ignoreSSLErrors = NO;
        if ([URL.host rangeOfString:@".onion"].location != NSNotFound) {
            #ifdef DEBUG
                NSLog(@"loading https://*.onion/ URL, ignoring SSL certificate status (%@)", URL.absoluteString);
            #endif
            ignoreSSLErrors = YES;
        } else {
            for (NSString *whitelistHost in appDelegate.sslWhitelistedDomains) {
                if ([whitelistHost isEqualToString:URL.host]) {
                    #ifdef DEBUG
                        NSLog(@"%@ in SSL host whitelist ignoring SSL certificate status", URL.host);
                    #endif
                    ignoreSSLErrors = YES;
                    break;
                }
            }
        }
        if (ignoreSSLErrors) {
            CFMutableDictionaryRef sslOption = CFDictionaryCreateMutable(kCFAllocatorDefault, 0, &kCFTypeDictionaryKeyCallBacks, &kCFTypeDictionaryValueCallBacks);
            CFDictionarySetValue(sslOption, kCFStreamSSLValidatesCertificateChain, kCFBooleanFalse);
            CFReadStreamSetProperty((__bridge CFReadStreamRef)_HTTPStream, kCFStreamPropertySSLSettings, sslOption);
        }
    }

    // Use tor proxy server
    NSString *hostKey = (NSString *)kCFStreamPropertySOCKSProxyHost;
    NSString *portKey = (NSString *)kCFStreamPropertySOCKSProxyPort;
    NSUInteger proxyPortNumber = 1080;

    NSMutableDictionary *proxyToUse = [NSMutableDictionary
                                       dictionaryWithObjectsAndKeys:@"127.0.0.1",hostKey,
                                       [NSNumber numberWithInt: proxyPortNumber],portKey,
                                       nil];
    CFReadStreamSetProperty((__bridge CFReadStreamRef)_HTTPStream, kCFStreamPropertySOCKSProxy, (__bridge CFTypeRef)proxyToUse);
    
    [_HTTPStream setDelegate:(id<NSStreamDelegate>)self];
    [_HTTPStream scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
    [_HTTPStream open];
}

- (void)_cancelStream
{
    // Support method to cancel the HTTP stream, but not change the delegate. Used for:
    //  A) Cancelling the connection
    //  B) Waiting to restart the connection while authentication takes place
    //  C) Restarting the connection after an HTTP redirect
    [_HTTPStream close];
    CFBridgingRelease((__bridge_retained CFTypeRef)(_HTTPStream));
    //[_HTTPStream release]; 
    _HTTPStream = nil;
}

- (void)cancel
{
    // Cancel the stream and stop the delegate receiving any more info
    [self _cancelStream];
    _delegate = nil;
}

- (void)stream:(NSInputStream *)theStream handleEvent:(NSStreamEvent)streamEvent
{
    NSParameterAssert(theStream == [self stream]);
    
    // Handle the response as soon as it's available
    if (!_haveReceivedResponse)
    {
        CFHTTPMessageRef response = (__bridge CFHTTPMessageRef)[theStream propertyForKey:(NSString *)kCFStreamPropertyHTTPResponseHeader];
        if (response && CFHTTPMessageIsHeaderComplete(response))
        {
            // Construct a NSURLResponse object from the HTTP message
            NSURL *URL = [theStream propertyForKey:(NSString *)kCFStreamPropertyHTTPFinalURL];
            NSHTTPURLResponse *URLResponse = [NSHTTPURLResponse responseWithURL:URL HTTPMessage:response];
            
            // If the response was an authentication failure, try to request fresh credentials.
            if ([URLResponse statusCode] == 401 || [URLResponse statusCode] == 407)
            {
                // Cancel any further loading and ask the delegate for authentication
                [self _cancelStream];
                
                NSAssert(![self currentAuthenticationChallenge],
                         @"Authentication challenge received while another is in progress");
                
                _authenticationChallenge = [[CKHTTPAuthenticationChallenge alloc] initWithResponse:response
                                                                                proposedCredential:nil
                                                                              previousFailureCount:_authenticationAttempts
                                                                                   failureResponse:URLResponse
                                                                                            sender:self];
                
                if ([self currentAuthenticationChallenge])
                {
                    _authenticationAttempts++;
                    [[self delegate] HTTPConnection:self didReceiveAuthenticationChallenge:[self currentAuthenticationChallenge]];
                    
                    return; // Stops the delegate being sent a response received message
                }
            }
            
            
            // By reaching this point, the response was not a valid request for authentication,
            // so go ahead and report it
            _haveReceivedResponse = YES;
            [[self delegate] HTTPConnection:self didReceiveResponse:URLResponse];
        }
    }
    
    
    
    // Next course of action depends on what happened to the stream
    switch (streamEvent)
    {
            
        case NSStreamEventErrorOccurred:    // Report an error in the stream as the operation failing
            [[self delegate] HTTPConnection:self didFailWithError:[theStream streamError]];
            break;
            
            
            
        case NSStreamEventEndEncountered:   // Report the end of the stream to the delegate
            [[self delegate] HTTPConnectionDidFinishLoading:self];
            break;
    
        
        case NSStreamEventHasBytesAvailable:
        {
            NSMutableData *data = [[NSMutableData alloc] initWithCapacity:1024];    // Report any data loaded to the delegate
            while ([theStream hasBytesAvailable])
            {
                uint8_t buf[1024];
                NSUInteger len = [theStream read:buf maxLength:1024];
                [data appendBytes:(const void *)buf length:len];
            }

            [[self delegate] HTTPConnection:self didReceiveData:data];
            break;
        }
            
        default:
            break;
    }
}

@end


#pragma mark -


@implementation CKHTTPConnection (Authentication)

- (CKHTTPAuthenticationChallenge *)currentAuthenticationChallenge { return _authenticationChallenge; }

- (void)_finishCurrentAuthenticationChallenge
{
    _authenticationChallenge = nil;
}

- (void)useCredential:(NSURLCredential *)credential forAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge
{
    NSParameterAssert(challenge == [self currentAuthenticationChallenge]);
    [self _finishCurrentAuthenticationChallenge];
    
    // Retry the request, this time with authentication // TODO: What if this function fails?
    CFHTTPAuthenticationRef HTTPAuthentication = [(CKHTTPAuthenticationChallenge *)challenge CFHTTPAuthentication];
    CFHTTPMessageApplyCredentials([self HTTPRequest],
                                  HTTPAuthentication,
                                  (__bridge CFStringRef)[credential user],
                                  (__bridge CFStringRef)[credential password],
                                  NULL);
    [self start];
}

- (void)continueWithoutCredentialForAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge
{
    NSParameterAssert(challenge == [self currentAuthenticationChallenge]);
    [self _finishCurrentAuthenticationChallenge];
    
    // Just return the authentication response to the delegate
    [[self delegate] HTTPConnection:self didReceiveResponse:(NSHTTPURLResponse *)[challenge failureResponse]];
    [[self delegate] HTTPConnectionDidFinishLoading:self];
}

- (void)cancelAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge
{
    NSParameterAssert(challenge == [self currentAuthenticationChallenge]);
    [self _finishCurrentAuthenticationChallenge];
    
    // Treat like a -cancel message
    [self cancel];
}

@end


#pragma mark -


@implementation NSURLRequest (CKHTTPURLRequest)

- (CFHTTPMessageRef)makeHTTPMessage
{
    CFHTTPMessageRef result = CFHTTPMessageCreateRequest(NULL,
                                                         (__bridge CFStringRef)[self HTTPMethod],
                                                         (__bridge CFURLRef)[self URL],
                                                         kCFHTTPVersion1_1);
    //[NSMakeCollectable(result) autorelease];
    
    AppDelegate *appDelegate = [[UIApplication sharedApplication] delegate];
    Byte spoofUserAgent = appDelegate.spoofUserAgent;

    
    NSDictionary *HTTPHeaderFields = [self allHTTPHeaderFields];
    NSEnumerator *HTTPHeaderFieldsEnumerator = [HTTPHeaderFields keyEnumerator];
    NSString *aHTTPHeaderField;
    while (aHTTPHeaderField = [HTTPHeaderFieldsEnumerator nextObject])
    {
        if (([aHTTPHeaderField isEqualToString:@"User-Agent"])&& (spoofUserAgent != UA_SPOOF_NO)){
            #ifdef DEBUG
                NSLog(@"Spoofing User-Agent");
            #endif
            NSString *uaString = @"";
            if (spoofUserAgent == UA_SPOOF_WIN7_TORBROWSER) {
                uaString = @"Mozilla/5.0 (Windows NT 6.1; rv:5.0) Gecko/20100101 Firefox/10.0";
            } else if (spoofUserAgent == UA_SPOOF_SAFARI_MAC) {
                uaString = @"Mozilla/5.0 (Macintosh; Intel Mac OS X 10_8_1) AppleWebKit/536.25 (KHTML, like Gecko) Version/6.0 Safari/536.25";
            }
            CFHTTPMessageSetHeaderFieldValue(result,
                                             (__bridge CFStringRef)aHTTPHeaderField,
                                             (__bridge CFStringRef)uaString);
            continue;
        }
        CFHTTPMessageSetHeaderFieldValue(result,
                                         (__bridge CFStringRef)aHTTPHeaderField,
                                         (__bridge CFStringRef)[HTTPHeaderFields objectForKey:aHTTPHeaderField]);
    }
    /* Do not track (DNT) header */
    Byte dntHeader = appDelegate.dntHeader;
    if (dntHeader != DNT_HEADER_UNSET) {
        // DNT_HEADER_CANTRACK is 0 and DNT_HEADER_NOTRACK is 1,
        // so we can pass that value in as the "DNT: X" value
        NSUInteger dntValue = 1;
        if (dntHeader == DNT_HEADER_CANTRACK) {
            dntValue = 0;
        }

        CFHTTPMessageSetHeaderFieldValue(result,
                                         (__bridge CFStringRef)@"DNT",
                                         (__bridge CFStringRef)[NSString stringWithFormat:@"%d",
                                                                dntValue]);
        #if DEBUG
        NSLog(@"Sending 'DNT: %d' header", dntValue);
        #endif
    }

    
    NSArray *cookies = [[NSHTTPCookieStorage sharedHTTPCookieStorage] cookiesForURL:[self URL]];
    if ([cookies count] > 0) {
        NSDictionary *cookieHeaders = [NSHTTPCookie requestHeaderFieldsWithCookies:cookies];
        for (NSString *headerKey in cookieHeaders) {
            CFHTTPMessageSetHeaderFieldValue(result,
                                             (__bridge CFStringRef)headerKey,
                                             (__bridge CFStringRef)[cookieHeaders objectForKey:headerKey]);
            /*NSLog(@"%@: %@",
                  headerKey,
                  [cookieHeaders objectForKey:headerKey]);
             */
        }
    }

    NSData *body = [self HTTPBody];
    if (body)
    {
        CFHTTPMessageSetBody(result, (__bridge_retained CFDataRef)body);
    }
    
    return result;  // NOT autoreleased/collectable
}

@end


#pragma mark -


@implementation NSHTTPURLResponse (CKHTTPConnectionAdditions)

+ (NSHTTPURLResponse *)responseWithURL:(NSURL *)URL HTTPMessage:(CFHTTPMessageRef)message
{
    return [[CKHTTPURLResponse alloc] initWithURL:URL HTTPMessage:message];
}

@end


@implementation CKHTTPURLResponse

- (id)initWithURL:(NSURL *)URL HTTPMessage:(CFHTTPMessageRef)message
{
    //_headerFields = NSMakeCollectable(CFHTTPMessageCopyAllHeaderFields(message));
    _headerFields = (__bridge_transfer NSDictionary *)CFHTTPMessageCopyAllHeaderFields(message);
    
    NSString *MIMEType = [_headerFields objectForKey:@"Content-Type"];
    NSInteger contentLength = [[_headerFields objectForKey:@"Content-Length"] intValue];
    NSString *encoding = [_headerFields objectForKey:@"Content-Encoding"];
    
    if (self = [super initWithURL:URL MIMEType:MIMEType expectedContentLength:contentLength textEncodingName:encoding])
    {
        _statusCode = CFHTTPMessageGetResponseStatusCode(message);
    }
    
    NSArray *newCookies = [NSHTTPCookie cookiesWithResponseHeaderFields:_headerFields forURL:[self URL]];
    [[NSHTTPCookieStorage sharedHTTPCookieStorage] setCookies:newCookies forURL:[self URL] mainDocumentURL:nil];
    //for (NSHTTPCookie *cookie in newCookies)
    //    NSLog(@"Name: %@ : Value: %@, Expires: %@", cookie.name, cookie.value, cookie.expiresDate);

    return self;
}
    
- (void)dealloc {
    CFRelease((__bridge_retained CFTypeRef)_headerFields);
}

- (NSDictionary *)allHeaderFields { return _headerFields;  }

- (NSInteger)statusCode { return _statusCode; }

@end


#pragma mark -


@implementation CKHTTPAuthenticationChallenge

/*  Returns nil if the ref is not suitable
 */
- (id)initWithResponse:(CFHTTPMessageRef)response
    proposedCredential:(NSURLCredential *)credential
  previousFailureCount:(NSInteger)failureCount
       failureResponse:(NSHTTPURLResponse *)URLResponse
                sender:(id <NSURLAuthenticationChallengeSender>)sender
{
    NSParameterAssert(response);
    
    
    // Try to create an authentication object from the response
    _HTTPAuthentication = CFHTTPAuthenticationCreateFromResponse(NULL, response);
    if (![self CFHTTPAuthentication])
    {
        return nil;
    }
    //CFMakeCollectable(_HTTPAuthentication);
    
    
    // NSURLAuthenticationChallenge only handles user and password
    if (!CFHTTPAuthenticationIsValid([self CFHTTPAuthentication], NULL))
    {
        return nil;
    }
    
    if (!CFHTTPAuthenticationRequiresUserNameAndPassword([self CFHTTPAuthentication]))
    {
        return nil;
    }
    
    
    // Fail if we can't retrieve decent protection space info
    CFArrayRef authenticationDomains = CFHTTPAuthenticationCopyDomains([self CFHTTPAuthentication]);
    NSURL *URL = [(__bridge NSArray *)authenticationDomains lastObject];
    CFRelease(authenticationDomains);
    
    if (!URL || ![URL host])
    {
        return nil;
    }
    
    
    // Fail for an unsupported authentication method
    CFStringRef authMethod = CFHTTPAuthenticationCopyMethod([self CFHTTPAuthentication]);
    NSString *authenticationMethod;
    if ([(__bridge NSString *)authMethod isEqualToString:(NSString *)kCFHTTPAuthenticationSchemeBasic])
    {
        authenticationMethod = NSURLAuthenticationMethodHTTPBasic;
    }
    else if ([(__bridge NSString *)authMethod isEqualToString:(NSString *)kCFHTTPAuthenticationSchemeDigest])
    {
        authenticationMethod = NSURLAuthenticationMethodHTTPDigest;
    }
    else
    {
        CFRelease(authMethod);
         // unsupported authentication scheme
        return nil;
    }
    CFRelease(authMethod);
    
    
    // Initialise
    CFStringRef realm = CFHTTPAuthenticationCopyRealm([self CFHTTPAuthentication]);
    
    NSURLProtectionSpace *protectionSpace = [[NSURLProtectionSpace alloc] initWithHost:[URL host]
                                                                                  port:([URL port] ? [[URL port] intValue] : 80)
                                                                              protocol:[URL scheme]
                                                                                 realm:(__bridge NSString *)realm
                                                                  authenticationMethod:authenticationMethod];
    CFRelease(realm);
    
    self = [self initWithProtectionSpace:protectionSpace
                      proposedCredential:credential
                    previousFailureCount:failureCount
                         failureResponse:URLResponse
                                   error:nil
                                  sender:sender];
    
    
    // Tidy up
    return self;
}

- (void)dealloc
{
    CFRelease(_HTTPAuthentication);
}

- (CFHTTPAuthenticationRef)CFHTTPAuthentication { return _HTTPAuthentication; }

@end

            
