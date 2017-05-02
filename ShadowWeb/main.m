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
        return UIApplicationMain(argc, argv, nil, NSStringFromClass([SWBAppDelegate class]));
    }
}
