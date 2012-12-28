//
//  WebViewController.h
//  OnionBrowser
//
//  Created by Mike Tigas on 2/25/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface WebViewController : UIViewController <UIWebViewDelegate, UITextFieldDelegate, UIActionSheetDelegate, UIAlertViewDelegate> {
}

@property (strong, nonatomic) UIWebView *myWebView;
@property (nonatomic) UIToolbar* toolbar;
@property (nonatomic) UIBarButtonItem* backButton;
@property (nonatomic) UIBarButtonItem* forwardButton;
@property (nonatomic) UIBarButtonItem* toolButton;
@property (nonatomic) UIActionSheet* optionsMenu;
@property (nonatomic) UIBarButtonItem* bookmarkButton;
@property (nonatomic) UIBarButtonItem* stopRefreshButton;
@property (nonatomic) UILabel* pageTitleLabel;
@property (nonatomic) UITextField* addressField;
@property (nonatomic) NSString *currentURL;

@property (nonatomic, retain) UINavigationController *bookmarkNavController;

@property (nonatomic) NSString *torStatus;

- (void)loadURL: (NSURL *)navigationURL;
- (void)addressBarCancel;
- (void)renderTorStatus: (NSString *)statusLine;

- (void)openOptionsMenu;
- (void)goForward;
- (void)goBack;
- (void)reload;
- (void)stopLoading;

- (void)prePopulateBookmarks;
- (void)showBookmarks;
- (void)addCurrentAsBookmark;
- (void)updateButtons;
- (void)updateTitle:(UIWebView*)aWebView;
- (void)updateAddress:(NSURLRequest*)request;
- (void)loadAddress:(id)sender event:(UIEvent*)event;
- (void)informError:(NSError*)error;

- (UIImage *)makeForwardBackButtonImage:(Boolean)whichButton;
@end
