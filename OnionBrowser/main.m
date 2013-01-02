//
//  main.m
//  OnionBrowser
//
//  Copyright (c) 2012 Mike Tigas. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "AppProxyCap.h"
#import "AppDelegate.h"

int main(int argc, char *argv[]) {
    @autoreleasepool {
		[AppProxyCap activate];
		[AppProxyCap setProxy:AppProxy_SOCKS Host:@"127.0.0.1" Port:1080];
//        [NSURLProtocol registerClass:[ProxyURLProtocol class]];
        return UIApplicationMain(argc, argv, nil, NSStringFromClass([AppDelegate class]));
    }
}
