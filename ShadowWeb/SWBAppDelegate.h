//
//  SWBAppDelegate.h
//  ShadowWeb
//
//  Created by clowwindy on 2/16/13.
//  Copyright (c) 2013 clowwindy. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "SWBNetworkActivityIndicatorManager.h"

#define appNetworkActivityIndicatorManager [(SWBAppDelegate *)[UIApplication sharedApplication].delegate networkActivityIndicatorManager]

@class SWBViewController;

@interface SWBAppDelegate : UIResponder <UIApplicationDelegate, UIAlertViewDelegate>

@property (strong, nonatomic) UIWindow *window;

@property (strong, nonatomic) SWBViewController *viewController;

@property (nonatomic, strong) SWBNetworkActivityIndicatorManager *networkActivityIndicatorManager;

- (void)setPolipo:(BOOL)enabled;
- (void)updateProxyMode;

@end
