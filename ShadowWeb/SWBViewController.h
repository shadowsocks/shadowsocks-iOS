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

#define kToolBarHeight 44
#define kCancelButtonWidth 70
#define kActionButtonWidth 44

@interface SWBViewController : UIViewController <UITextFieldDelegate, SWBTabBarDelegate, SWBWebViewContainerDelegate, UIScrollViewDelegate, UIActionSheetDelegate> {
    NSInteger lastTag;
    NSInteger currentTabTag;
}

@property (nonatomic, strong) SWBTabBarView *tabBar;
@property (nonatomic, strong) SWBWebViewContainer *webViewContainer;
@property (nonatomic, retain) UIActionSheet *actionSheet;
@property (nonatomic, retain) SWBPageManager *pageManager;

@property (strong, nonatomic) UIToolbar *addrbar;
@property (strong, nonatomic) NSMutableArray *addrItemsActive;
@property (strong, nonatomic) NSMutableArray *addrItemsInactive;
@property (strong, nonatomic) UITextField *urlField;




-(void)openLinkInNewTab:(NSString *)urlString;
-(void)savePageIndex;
-(void)saveData;

@end
