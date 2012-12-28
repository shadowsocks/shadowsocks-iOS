//
//  ProxyURLProtocol.h
//  PandoraBoy
//
//  Created by Rob Napier on 11/30/07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//
// Special NSURLProtocol to capture information out of the stream.
// It does very little; most work is done by subclasses

#import "CKHTTPConnection.h"

@interface ProxyURLProtocol : NSURLProtocol <CKHTTPConnectionDelegate> {
    NSURLRequest *_request;
    CKHTTPConnection *_connection;
    NSMutableData *_data;
    Boolean isGzippedResponse;
}

- (NSMutableData *)data;

@end
