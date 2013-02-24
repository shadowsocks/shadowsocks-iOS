//
//  main.m
//  ShadowWeb
//
//  Created by clowwindy on 2/16/13.
//  Copyright (c) 2013 clowwindy. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "AppProxyCap.h"
#import "SWBAppDelegate.h"

int main(int argc, char *argv[])
{
    @autoreleasepool {
		[AppProxyCap activate];
		[AppProxyCap setProxy:AppProxy_SOCKS Host:@"127.0.0.1" Port:1080];
        return UIApplicationMain(argc, argv, nil, NSStringFromClass([SWBAppDelegate class]));
    }
}
