//
//  SWBViewController.h
//  ShadowWeb
//
//  Created by clowwindy on 2/16/13.
//  Copyright (c) 2013 clowwindy. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "SWBTabBarView.h"
#import "SWBWebViewContainer.h"
#import "SWBPageManager.h"

@interface SWBViewController : UIViewController <SWBTabBarDelegate, SWBWebViewContainerDelegate> {
    NSInteger lastTag;
    NSInteger currentTabTag;
}

@property (nonatomic, strong) SWBTabBarView *tabBar;
@property (nonatomic, strong) SWBWebViewContainer *webViewContainer;
@property (nonatomic, retain) UIToolbar *toolBar;
@property (nonatomic, retain) UIActionSheet *actionSheet;
@property (nonatomic, retain) SWBPageManager *pageManager;

-(void)openLinkInNewTab:(NSString *)urlString;
-(void)savePageIndex;
-(void)saveData;

@end
