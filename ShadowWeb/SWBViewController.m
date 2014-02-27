//
//  SWBViewController.m
//  ShadowWeb
//
//  Created by clowwindy on 2/16/13.
//  Copyright (c) 2013 clowwindy. All rights reserved.
//

#import <AVFoundation/AVFoundation.h>
#import "QRCodeViewController.h"
#import "SWBViewController.h"
#import "ShadowsocksRunner.h"
#import "ProxySettingsTableViewController.h"
#import "SWBAboutController.h"

#define kNewTabAddress @"shadowweb:newtab"
#define kAboutBlank @"shadowweb:blank"

@interface SWBViewController () {
    AVAudioPlayer *player;
    UIPopoverController *settingsPC;
    UIBarButtonItem *actionBarButton;
}

@end

@implementation SWBViewController

#pragma mark - View lifecycle

- (UIStatusBarStyle)preferredStatusBarStyle {
    return UIStatusBarStyleDefault;
}

- (UIRectEdge) edgesForExtendedLayout {
    return UIRectEdgeNone;
}

- (CGFloat) statusBarHeight {
    return ([[[UIDevice currentDevice] systemVersion] floatValue] >= 7.0) ?
        20 : 0;
}

- (void)viewDidLoad {
    [super viewDidLoad];

    // If don't do this, you'll see some white edge when doing the rotation
    self.view.clipsToBounds = YES;
    self.view.backgroundColor = [UIColor whiteColor];
    
    currentTabTag = 0;
    CGRect bounds = self.view.bounds;
    self.tabBar = [[SWBTabBarView alloc] initWithFrame:CGRectMake(0, bounds.size.height - kTabBarHeight, bounds.size.width, kTabBarHeight)];
    self.webViewContainer = [[SWBWebViewContainer alloc] initWithFrame:CGRectMake(0, 0, bounds.size.width, bounds.size.height - kTabBarHeight)];
//    _webViewContainer.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
    _webViewContainer.delegate = self;
    self.tabBar.delegate = self;
    self.webViewContainer.delegate = self;
    [self initPageManager];
    [self initPagesAndTabs];


    // init address bar
    self.addrbar = [[UIToolbar alloc] initWithFrame:CGRectMake(0, [self statusBarHeight], bounds.size.width, kToolBarHeight)];
    // init bar buttons

    
    CGRect urlFieldFrame = CGRectInset(_addrbar.bounds, 12 + kActionButtonWidth * 0.5f, 7);
    urlFieldFrame = CGRectOffset(urlFieldFrame, -kActionButtonWidth * 0.5f, 0);
    self.urlField = [[UITextField alloc] initWithFrame:urlFieldFrame];
    [_urlField setBorderStyle:UITextBorderStyleRoundedRect];
    [_urlField setKeyboardType:UIKeyboardTypeURL];
    UIBarButtonItem *item = [[UIBarButtonItem alloc] initWithCustomView:_urlField];
    [item setStyle:UIBarButtonItemStylePlain];
    [_urlField setReturnKeyType:UIReturnKeyGo];
    [_urlField setDelegate:self];
    [_urlField addTarget:self action:@selector(textFieldDidEndEditing) forControlEvents:UIControlEventEditingDidEndOnExit];
    [_urlField setContentVerticalAlignment:UIControlContentVerticalAlignmentCenter];
    [_urlField setAutocapitalizationType:UITextAutocapitalizationTypeNone];
    [_urlField setAutocorrectionType:UITextAutocorrectionTypeNo];
    [_urlField setClearButtonMode:UITextFieldViewModeWhileEditing];
    [_urlField setPlaceholder:@"URL"];
    [_urlField setAutoresizingMask:UIViewAutoresizingFlexibleWidth];

    UIBarButtonItem *_cancelButton = [[UIBarButtonItem alloc] initWithTitle:_L(Cancel) style:UIBarButtonItemStyleBordered target:self action:@selector(cancel)];
    _cancelButton.width = kCancelButtonWidth;
    UIBarButtonItem *_actionButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAction target:self action:@selector(addrBarViewMoreDidClick)];
    _actionButton.width = kActionButtonWidth;
    actionBarButton = _actionButton;
    
    self.addrItemsInactive = [NSMutableArray arrayWithObjects:
                            [[UIBarButtonItem alloc] initWithCustomView:_urlField],
                            [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil],
                            _actionButton,
                            nil];
    self.addrItemsActive = [NSMutableArray arrayWithObjects:
                            [self.addrItemsInactive objectAtIndex:0],
                            _cancelButton,
                            nil];

    [_addrbar setItems:_addrItemsInactive];
//    [_addrbar setBarStyle:UIBarStyleBlack];
    if ([_addrbar respondsToSelector:@selector(setBarTintColor:)]) {
        [_addrbar setBarTintColor:[UIColor whiteColor]];
    }

    // add subviews
    [self.view addSubview:_webViewContainer];
    [self.view addSubview:_addrbar];
    [self.view addSubview:_tabBar];

    [self relayout:bounds];

    // Keyboard hide notification
    [[NSNotificationCenter defaultCenter]
            addObserver:self
               selector:@selector(keyboardHiden:)
                   name:UIKeyboardWillHideNotification
                 object:nil];

    // ActionSheet
    [self initActionSheet];

//    [self play];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
    [_webViewContainer releaseBackgroundWebViews];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    return YES;
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation {
    [self scrollViewDidScroll:[self currentWebView].scrollView];
}

- (void)viewWillLayoutSubviews {
    [self relayout:self.view.bounds];
}

- (void)relayout:(CGRect)bounds {
    CGRect addrBarRect = CGRectMake(0, _addrbar.frame.origin.y, bounds.size.width, kToolBarHeight);
    CGRect webViewContainerRect = CGRectMake(0, [self statusBarHeight], bounds.size.width, bounds.size.height - kTabBarHeight - [self statusBarHeight]);
    CGRect tabBarRect = CGRectMake(0, bounds.size.height - kTabBarHeight, bounds.size.width, kTabBarHeight);
    _addrbar.frame = addrBarRect;
    _webViewContainer.frame = webViewContainerRect;
    _tabBar.frame = tabBarRect;
}

- (void)viewDidAppear:(BOOL)animated {
    if ([ShadowsocksRunner settingsAreNotComplete]) {
        [self showSettings];
    }
}

#pragma mark - webview

- (void)updateWebViewTitle:(UIWebView *)webView {
    NSString *title = [_webViewContainer titleForWebView:(SWBWebView *) webView];

    SWBPage *page = [_pageManager pageByTag:webView.tag];
    if (title) {
        page.title = title;
//        [visitRecordManager setTitleForURL:[(AQWebView *)webView aqLocationHref] title:title];
    }
    if (title == nil || [title isEqualToString:@""]) {
        if (webView.loading) {
            title = NSLocalizedString(@"Loading", "Loading");
        } else {
            title = NSLocalizedString(@"Untitled", "Untitled");
        }
    }
    [_tabBar setTitleForTab:webView.tag title:title];
}

- (void)openURL:(NSString *)urlString {
    NSURL *url = [NSURL URLWithString:urlString];
    if (!url || [urlString rangeOfString:@":"].length == 0) {
        urlString = [@"http://" stringByAppendingString:urlString];
        url = [NSURL URLWithString:urlString];
    }
    if (url) {
        NSURLRequest *request = [NSURLRequest requestWithURL:url];
        if (request) {
            [_webViewContainer.currentSWBWebView loadRequest:request];
        }
    } else {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:nil message:_L(incorrect
        URL)                                           delegate:nil cancelButtonTitle:_L(OK) otherButtonTitles:nil];
        [alert show];
    }
}

- (SWBWebView *)currentWebView {
    return [_webViewContainer currentSWBWebView];
}

- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error {

}

- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType {
    BOOL result = YES;

#ifdef DEBUG
    //    NSLog(@"shouldStartLoadWithRequest tag:%d navtype:%d %@", webView.tag, navigationType, [request URL]);
#endif
    //    NSString *scheme = [[request URL] scheme];

    if ([[[request URL] absoluteString] caseInsensitiveCompare:kNewTabAddress] == NSOrderedSame) {
//        [self openLinkInNewTab:[(SWBWebView *)webView lastClickedLink]];
    }
    else {
        if (navigationType == UIWebViewNavigationTypeLinkClicked ||
                navigationType == UIWebViewNavigationTypeBackForward) {
            SWBPage *page = [_pageManager pageByTag:webView.tag];
            NSString *url = [[request URL] absoluteString];
            page.url = url;
        }
    }
    return result;
}

- (void)webViewDidFinishLoad:(UIWebView *)webView {
    [self resetTabBarButtonsStatus];
    [self updateWebViewTitle:webView];

    [_tabBar setLoadingForTab:webView.tag loading:NO];

    if ([[[[webView request] URL] absoluteString] caseInsensitiveCompare:[(SWBWebView *) webView locationHref]] == NSOrderedSame) {
        NSString *url = [[[webView request] URL] absoluteString];
        NSString *title = [((SWBWebView *) webView) pageTitle];
        _urlField.text = url;
        SWBPage *page = [_pageManager pageByTag:webView.tag];
        page.url = url;
        page.title = title;

    }
}

- (void)webViewDidStartLoad:(UIWebView *)webView {
    [_tabBar setLoadingForTab:webView.tag loading:YES];
}

#pragma mark - WebView Scrolling

- (void)initWebViewScrolling:(SWBWebView *)webView {
    UIScrollView *scrollView = webView.scrollView;
    scrollView.delegate = self;
    [scrollView setContentInset:UIEdgeInsetsMake(kToolBarHeight, 0, 0, 0)];
    [scrollView setScrollIndicatorInsets:UIEdgeInsetsMake(kToolBarHeight, 0, 0, 0)];
    [scrollView scrollRectToVisible:CGRectMake(0, 0, 1, 1) animated:NO];
    [self scrollViewDidScroll:scrollView];
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    if ([self currentWebView].scrollView == scrollView) {
        if (scrollView.contentOffset.y < 0) {
            [scrollView setScrollIndicatorInsets:UIEdgeInsetsMake(-scrollView.contentOffset.y, 0, 0, 0)];
        } else {
            [scrollView setScrollIndicatorInsets:UIEdgeInsetsMake(0, 0, 0, 0)];
        }
        _addrbar.frame = CGRectMake(0, [self statusBarHeight] - kToolBarHeight - scrollView.contentOffset.y, _addrbar.frame.size.width, kToolBarHeight);
        
        CGFloat offset = MIN(kToolBarHeight, MAX(0, (kToolBarHeight + scrollView.contentOffset.y)));
        CGFloat opacity = offset / kToolBarHeight;
        _urlField.alpha = (1 - opacity)*(1 - opacity);
        // NSLog(@"offset: %f, contentInset top: %f", offset, scrollView.contentInset.top);
        [scrollView setContentInset:UIEdgeInsetsMake(kToolBarHeight - offset, 0, 0, 0)];
    }
}

#pragma mark - ActionSheet

- (void)initActionSheet {
    self.actionSheet = [[UIActionSheet alloc] initWithTitle:nil delegate:self cancelButtonTitle:_L(Cancel) destructiveButtonTitle:nil otherButtonTitles:_L(New
    Tab), _L(Back), _L(Forward), _L(Reload), _L(Settings), _L(Config via QRCode), _L(Help), _L(About), nil];
    [_actionSheet setActionSheetStyle:UIActionSheetStyleBlackTranslucent];
}

- (void)actionSheet:(UIActionSheet *)actionSheet didDismissWithButtonIndex:(NSInteger)buttonIndex {
    QRCodeViewController *qrCodeViewController = [[QRCodeViewController alloc] initWithReturnBlock:^(NSString *code) {
        if (code) {
            NSURL *URL = [NSURL URLWithString:code];
            if (URL) {
                [[UIApplication sharedApplication] openURL:URL];
            }
        }
    }];
    switch (buttonIndex) {
        case 0:
            [self openLinkInNewTab:kNewTabAddress];
            _urlField.text = @"";
            [NSTimer scheduledTimerWithTimeInterval:0.20 target:_urlField selector:@selector(becomeFirstResponder) userInfo:nil repeats:NO];
            break;
        case 1:
            [[self currentWebView] goBack];
            break;
        case 2:
            [[self currentWebView] goForward];
            break;
        case 3:
            [[self currentWebView] reload];
            break;
        case 4:
            [self showSettings];
            break;
        case 5:
            [self presentModalViewController:qrCodeViewController animated:YES];
            break;
        case 6:
            [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"https://github.com/shadowsocks/shadowsocks-iOS/wiki/Help"]];
            break;
        case 7:
            [self showAbout];
            break;
        default:
            break;
    }
}

- (void)showAbout {
    SWBAboutController *settingsController = [[SWBAboutController alloc] initWithStyle:UITableViewStyleGrouped];
    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:settingsController];
    //    nav.navigationBar.tintColor = [UIColor blackColor];
//    nav.navigationBar.barStyle = UIBarStyleBlackOpaque;
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        settingsPC = [[UIPopoverController alloc] initWithContentViewController:nav];
        settingsController.myPopoverController = settingsPC;
        CGRect newTabRect = [self.tabBar aNewTabButton].frame;
        newTabRect.size.width = newTabRect.size.height;
        CGRect rect = [self.tabBar convertRect:newTabRect toView:self.view];
//        [settingsPC presentPopoverFromRect:rect inView:self.view permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
        [settingsPC presentPopoverFromBarButtonItem:actionBarButton permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
    } else {
        [self presentModalViewController:nav animated:YES];
    }

}

- (void)showSettings {
    ProxySettingsTableViewController *settingsController = [[ProxySettingsTableViewController alloc] initWithStyle:UITableViewStyleGrouped];
    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:settingsController];
    //    nav.navigationBar.tintColor = [UIColor blackColor];
//    nav.navigationBar.barStyle = UIBarStyleBlackOpaque;
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        settingsPC = [[UIPopoverController alloc] initWithContentViewController:nav];
        settingsController.myPopoverController = settingsPC;
        CGRect newTabRect = [self.tabBar aNewTabButton].frame;
        newTabRect.size.width = newTabRect.size.height;
        CGRect rect = [self.tabBar convertRect:newTabRect toView:self.view];
//        [settingsPC presentPopoverFromRect:rect inView:self.view permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
        [settingsPC presentPopoverFromBarButtonItem:actionBarButton permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
    } else {
        [self presentModalViewController:nav animated:YES];
    }
}

#pragma mark - TabBar


- (void)resetTabBarButtonsStatus {
//    SWBWebView *currentWebView = [self currentWebView];
//    backButton.enabled = currentWebView.canGoBack;
//    forwardButton.enabled = currentWebView.canGoForward;
//    stopButton.enabled = currentWebView.loading;
//    @try {
//        NSString *urlString = [[self currentWebView] aqLocationHref];
//        NSURL *url = [NSURL URLWithString:urlString];
//        if (AQ_is_nonlocal_http([url scheme])) {
//            actionButton.enabled = YES;
//            //            refreshButton.enabled = YES;
//        } else {
//            actionButton.enabled = NO;
//            //            refreshButton.enabled = NO;
//        }
//    }
//    @catch (NSException *exception) {
//    }
//    @finally {
//    }
}


- (void)tabBarViewNewTabButtonDidClick {
    [self openLinkInNewTab:kNewTabAddress];
    _urlField.text = @"";
    [NSTimer scheduledTimerWithTimeInterval:0.20 target:_urlField selector:@selector(becomeFirstResponder) userInfo:nil repeats:NO];
}

- (void)addrBarViewMoreDidClick {
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        CGRect newTabRect = [self.tabBar aNewTabButton].frame;
        newTabRect.size.width = newTabRect.size.height;
        CGRect rect = [self.tabBar convertRect:newTabRect toView:self.view];
//        [self.actionSheet showFromRect:rect inView:self.view animated:YES];
        [self.actionSheet showFromBarButtonItem:actionBarButton animated:YES];
    } else {
        [self.actionSheet showInView:self.view];
    }
}

- (void)tabBarViewTabDidClose:(SWBTab *)tab {
//    NSString *title = [[_webViewContainer webViewByTag:tab.tag] pageTitle];
//    NSString *urlString =[[_pageManager pageByTag:tab.tag] url];
//    if (urlString) {
//        NSURL *url = [[NSURL alloc] initWithString:urlString];
//        if (AQ_is_nonlocal_http([url scheme])) {
//            [visitRecordManager closeAURL:urlString withTitle:title];
//        }
//        [url release];
//    }
    [_pageManager removePage:tab.tag];
    [_webViewContainer closeWebView:tab.tag];
    if (_tabBar.currentTab) {
        [_webViewContainer switchToWebView:_tabBar.currentTab.tag];
    }
    if ([[_pageManager pages] count] == 0) {
//        [self tabBarViewNewTabButtonDidClick];
        [self openLinkInNewTab:@"http://www.twitter.com/"];
        [NSTimer scheduledTimerWithTimeInterval:0.20 target:_urlField selector:@selector(becomeFirstResponder) userInfo:nil repeats:NO];
    }
}

- (void)tabBarViewTabDidMove:(SWBTab *)tab toIndex:(NSInteger)index {
    //    [pageManager reorderPage:tabBar.tabs];
    // 目前没有必要
}

- (void)tabBarViewTabDidSelect:(SWBTab *)tab {
    [_webViewContainer switchToWebView:tab.tag];
}

#pragma mark - page manager

- (void)initPageManager {
    lastTag = 0;
    self.pageManager = [[SWBPageManager alloc] init];
    [_pageManager load];
}

- (NSInteger)genTag {
    return lastTag++;
}

- (void)initPagesAndTabs {
    [_pageManager initMappingAndTabsByPages];
    NSArray *pages = _pageManager.pages;
//    NSInteger currentTabTag = 0;
    NSUInteger count = [pages count];
    for (int i = 0; i < count; i++) {
        if ([[[pages objectAtIndex:i] selected] boolValue]) {
            currentTabTag = i;
        }
    }
    for (int i = 0; i < count; i++) {
        [self addNewTab];
    }
    if ([pages count] == 0) {
//        [self tabBarViewNewTabButtonDidClick];
        [self openLinkInNewTab:@"http://www.google.com/"];
        [NSTimer scheduledTimerWithTimeInterval:0.20 target:_urlField selector:@selector(becomeFirstResponder) userInfo:nil repeats:NO];
    } else {
        [_tabBar setCurrentTabWithTag:currentTabTag];
    }
}

- (void)savePageIndex {
    // save page index order
    //    NSArray *tabs = [tabBar tabs];
    //    for (int i = 0; i < [tabs count]; i++) {
    //        [[pageManager pageByTag:[[tabs objectAtIndex:i] tag]] setIndex:[NSNumber numberWithInt:i]];
    //    }
}

- (void)addNewEmptyTab {
    NSInteger newTag = [self genTag];
    [_webViewContainer newWebView:newTag];
}

- (void)addNewTab {
    SWBTab *newTab = [_tabBar newTab];
    [_webViewContainer newWebView:newTab.tag];
    _tabBar.currentTab = newTab;
}

- (void)openLinkInNewTab:(NSString *)urlString {
    SWBTab *newTab = [_tabBar newTab];
    SWBPage *page = [_pageManager addPageWithTag:newTab.tag];
    page.url = urlString;
    page.title = @"";
    [_webViewContainer newWebView:newTab.tag];
    _tabBar.currentTab = newTab;
}


- (void)saveData {
    [_pageManager save];
}

#pragma mark - WebViewContainer

- (void)syncPageManagerSelectionStatusWithSelectedTag:(NSInteger)tag {
    NSNumber *yes = [NSNumber numberWithBool:YES];
    NSNumber *no = [NSNumber numberWithBool:NO];
    for (SWBPage *page in _pageManager.pages) {
        page.selected = no;
    }
    [_pageManager pageByTag:tag].selected = yes;
}

- (void)webViewContainerWebViewDidCreateNew:(SWBWebView *)webView {
    SWBPage *page = [_pageManager pageByTag:webView.tag];
    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:page.url]];
    [webView loadRequest:request];

    [self initWebViewScrolling:webView];

    [self resetTabBarButtonsStatus];
    [self syncPageManagerSelectionStatusWithSelectedTag:webView.tag];
}

- (void)webViewContainerWebViewDidSwitchToWebView:(SWBWebView *)webView {
    [self resetTabBarButtonsStatus];
    [self syncPageManagerSelectionStatusWithSelectedTag:webView.tag];
    _urlField.text = webView.locationHref;
    [self scrollViewDidScroll:webView.scrollView];
}

- (void)webViewContainerWebViewNeedToReload:(SWBWebView *)webView tag:(NSInteger)tag {
    SWBPage *page = [_pageManager pageByTag:tag];
    NSURL *url = [NSURL URLWithString:page.url];
    if (url != nil) {
        NSURLRequest *request = [NSURLRequest requestWithURL:url];
        [webView loadRequest:request];
        [self resetTabBarButtonsStatus];
    }
}



#pragma mark - Text Field

- (void)hideKeyboard {
    [_urlField resignFirstResponder];
    [self hideCancelButton];
}

- (void)hideCancelButton {
    [_addrbar setItems:_addrItemsInactive animated:YES];
    
    [UIView beginAnimations:nil context:NULL];
    CGRect bounds = [_addrbar bounds];
    bounds = CGRectInset(bounds, 12 + kActionButtonWidth * 0.5f, 7);
    bounds = CGRectOffset(bounds, -kActionButtonWidth * 0.5f, 0);
    [_urlField setFrame:bounds];
    [UIView commitAnimations];
}

- (void)cancel {
    [self hideKeyboard];
}


- (void)textFieldDidBeginEditing:(UITextField *)textField {
    [_addrbar setItems:_addrItemsActive animated:YES];

    [UIView beginAnimations:nil context:NULL];
    CGRect bounds = [_addrbar bounds];
    bounds = CGRectInset(bounds, 12 + kCancelButtonWidth * 0.5f, 7);
    bounds = CGRectOffset(bounds, -kCancelButtonWidth * 0.5f, 0);
    [_urlField setFrame:bounds];
    [UIView commitAnimations];
}

- (void)textFieldDidEndEditing {
    [self hideKeyboard];
    [self openURL:_urlField.text];
}

- (BOOL)textFieldShouldEndEditing:(UITextField *)textField {
    return YES;
}

- (void)keyboardHiden:(NSNotification *)notification {
//    [self hideCancelButton];
}

#pragma mark audio

- (BOOL)canBecomeFirstResponder {
    return YES;
}

- (void)play {

    // Play music, so app can run in the backgound.
    AVAudioSession *session = [AVAudioSession sharedInstance];
    [session setActive:YES error:nil];
    [session setCategory:AVAudioSessionCategoryPlayback error:nil];

    [[UIApplication sharedApplication] beginReceivingRemoteControlEvents];
    NSURL *url = [[NSBundle mainBundle] URLForResource:@"silence" withExtension:@"wav"];

    player = [[AVAudioPlayer alloc] initWithContentsOfURL:url error:nil];
    [player prepareToPlay];
    [player setVolume:0];
    player.numberOfLoops = -1;
    [player play];
    [self becomeFirstResponder];
}


- (void)remoteControlReceivedWithEvent:(UIEvent *)event {
    switch (event.subtype) {
        case UIEventSubtypeRemoteControlPlay:
            [player play];
            break;
        case UIEventSubtypeRemoteControlPause:
            [player pause];
            break;
        default:
            break;
    }
}

@end
