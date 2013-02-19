//
//  SWBViewController.m
//  ShadowWeb
//
//  Created by clowwindy on 2/16/13.
//  Copyright (c) 2013 clowwindy. All rights reserved.
//

#import "SWBViewController.h"

#define kNewTabAddress @"shadowweb:newtab"
#define kAboutBlank @"shadowweb:blank"

@interface SWBViewController ()

@end

@implementation SWBViewController

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    currentTabTag = 0;
    CGRect bounds = self.view.bounds;
    self.tabBar = [[SWBTabBarView alloc] initWithFrame:CGRectMake(0, bounds.size.height - kTabBarHeight, bounds.size.width, kTabBarHeight)];
    [self.view addSubview:self.tabBar];
    self.webViewContainer = [[SWBWebViewContainer alloc] initWithFrame:CGRectMake(0, 0, bounds.size.width, bounds.size.height - kTabBarHeight)];
    _webViewContainer.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
    [self.view addSubview:_webViewContainer];
    _webViewContainer.delegate = self;
    self.tabBar.delegate = self;
    self.webViewContainer.delegate = self;
    [self initPageManager];
    [self initPagesAndTabs];
    
    
    // init address bar
    self.addrbar = [[UIToolbar alloc] initWithFrame:CGRectMake(0, 0, bounds.size.width, kToolBarHeight)];
    
    // init bar buttons
    
    self.urlField = [[UITextField alloc] initWithFrame:CGRectMake(12, 7, 260, 31)];
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
    
    self.cancelButton = [[UIBarButtonItem alloc] initWithTitle:@"Cancel" style:UIBarButtonItemStyleBordered target:self action:@selector(cancel) ];
    
    self.addrItemsInactive = [NSMutableArray arrayWithObjects:[[UIBarButtonItem alloc] initWithCustomView:_urlField], [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil], nil];
    self.addrItemsActive = [NSMutableArray arrayWithArray:_addrItemsInactive];
    [_addrItemsActive addObject:_cancelButton];
    
    [_addrbar setItems:_addrItemsInactive];
    [_addrbar setBarStyle:UIBarStyleBlackOpaque];
    [_addrbar setTintColor:[UIColor colorWithWhite:0.6f alpha:1.0f]];
    
    // add subviews
    [self.view addSubview:_addrbar];

    // Keyboard hide notification
    [[NSNotificationCenter defaultCenter]
     addObserver:self
     selector:@selector(keyboardHiden:)
     name:UIKeyboardWillHideNotification
     object:nil];

}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
    [_webViewContainer releaseBackgroundWebViews];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
	return YES;
}


#pragma mark - webview

-(void)updateWebViewTitle:(UIWebView *)webView {
    NSString *title = [_webViewContainer titleForWebView:(SWBWebView *)webView];
    
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
    [_tabBar setTitleForTab:webView.tag title: title];
}

-(void)openURL:(NSString *)urlString {
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
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:nil message:@"incorrect URL" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
        [alert show];
    }
}

-(SWBWebView *)currentWebView {
    return [_webViewContainer currentSWBWebView];
}

-(void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error {
    
}

-(BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType {
    BOOL result = YES;
    
#ifdef DEBUG
    //    NSLog(@"shouldStartLoadWithRequest tag:%d navtype:%d %@", webView.tag, navigationType, [request URL]);
#endif
    //    NSString *scheme = [[request URL] scheme];
    
    if ([[[request URL] absoluteString] caseInsensitiveCompare:kNewTabAddress] == NSOrderedSame)
    {
//        [self openLinkInNewTab:[(SWBWebView *)webView lastClickedLink]];
    }
    else
    {
        if (navigationType == UIWebViewNavigationTypeLinkClicked ||
            navigationType == UIWebViewNavigationTypeBackForward) {
            SWBPage *page = [_pageManager pageByTag:webView.tag];
            NSString *url = [[request URL] absoluteString];
            page.url = url;
        }
    }
    return result;
}

-(void)webViewDidFinishLoad:(UIWebView *)webView {
    [self resetTabBarButtonsStatus];
    [self updateWebViewTitle:webView];
    
    [_tabBar setLoadingForTab:webView.tag loading:NO];

    if ([[[[webView request] URL] absoluteString] caseInsensitiveCompare: [(SWBWebView *)webView locationHref]] == NSOrderedSame) {
        NSString *url = [[[webView request] URL] absoluteString];
        NSString *title = [((SWBWebView *)webView) pageTitle];
        _urlField.text = url;
        SWBPage *page = [_pageManager pageByTag:webView.tag];
        page.url = url;
        page.title = title;
        
    }
}

-(void)webViewDidStartLoad:(UIWebView *)webView {
    
}

#pragma mark - WebView Scrolling

-(void)initWebViewScrolling:(SWBWebView *)webView {
    UIScrollView *scrollView = webView.scrollView;
    scrollView.delegate = self;
    [scrollView setContentInset:UIEdgeInsetsMake(kToolBarHeight, 0, 0, 0)];
    [self scrollViewDidScroll:scrollView];
}

-(void)scrollViewDidScroll:(UIScrollView *)scrollView {
    _addrbar.frame = CGRectMake(0, -kToolBarHeight - scrollView.contentOffset.y, _addrbar.frame.size.width, kToolBarHeight);
}

#pragma mark - TabBar


-(void)resetTabBarButtonsStatus {
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


-(void)tabBarViewNewTabButtonDidClick {
    [self openLinkInNewTab:kNewTabAddress];
    _urlField.text = @"";
    [NSTimer scheduledTimerWithTimeInterval:0.25 target:_urlField selector:@selector(becomeFirstResponder) userInfo:nil repeats:NO];
}

-(void)tabBarViewTabDidClose:(SWBTab *)tab {
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
        [self tabBarViewNewTabButtonDidClick];
    }
}

-(void)tabBarViewTabDidMove:(SWBTab *)tab toIndex:(NSInteger)index {
    //    [pageManager reorderPage:tabBar.tabs];
    // 目前没有必要
}

-(void)tabBarViewTabDidSelect:(SWBTab *)tab {
    [_webViewContainer switchToWebView:tab.tag];
}

#pragma mark - page manager

-(void)initPageManager {
    lastTag = 0;
    self.pageManager = [[SWBPageManager alloc] init];
    [_pageManager load];
}

-(NSInteger)genTag {
    return lastTag ++;
}

-(void)initPagesAndTabs {
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
        [self tabBarViewNewTabButtonDidClick];
    } else {
        [_tabBar setCurrentTabWithTag:currentTabTag];
    }
}

-(void)savePageIndex {
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

-(void)openLinkInNewTab:(NSString *)urlString {
    SWBTab *newTab = [_tabBar newTab];
    SWBPage *page = [_pageManager addPageWithTag:newTab.tag];
    page.url = urlString;
    page.title = @"";
    [_webViewContainer newWebView:newTab.tag];
    _tabBar.currentTab = newTab;
}


-(void)saveData {
    [_pageManager save];
}

#pragma mark - WebViewContainer

-(void)syncPageManagerSelectionStatusWithSelectedTag:(NSInteger)tag {
    NSNumber *yes = [NSNumber numberWithBool:YES];
    NSNumber *no = [NSNumber numberWithBool:NO];
    for (SWBPage *page in _pageManager.pages) {
        page.selected = no;
    }
    [_pageManager pageByTag:tag].selected = yes;
}

-(void)webViewContainerWebViewDidCreateNew:(SWBWebView *)webView {
    SWBPage *page = [_pageManager pageByTag:webView.tag];
    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:page.url]];
    NSRange range = [page.url rangeOfString:@"file:"];
    if (range.length > 0 && range.location == 0) {
        if ([page.url rangeOfString:@"home.min.htm"].length > 0) {
            request = [NSURLRequest requestWithURL:[NSURL URLWithString:kAboutBlank]];
        }
    }
    
    [webView loadRequest:request];
    
    [self initWebViewScrolling:webView];
    
    [self resetTabBarButtonsStatus];
    [self syncPageManagerSelectionStatusWithSelectedTag:webView.tag];
}

-(void)webViewContainerWebViewDidSwitchToWebView:(SWBWebView *)webView {
    [self resetTabBarButtonsStatus];
    [self syncPageManagerSelectionStatusWithSelectedTag:webView.tag];
    _urlField.text = webView.locationHref;
    [self scrollViewDidScroll:webView.scrollView];
}

-(void)webViewContainerWebViewNeedToReload:(SWBWebView *)webView tag:(NSInteger)tag {
    SWBPage *page = [_pageManager pageByTag:tag];
    NSURL *url = [NSURL URLWithString:page.url];
    if (url!=nil) {
        NSURLRequest *request = [NSURLRequest requestWithURL:url];
        [webView loadRequest:request];
        [self resetTabBarButtonsStatus];
    }
}



#pragma mark - Text Field

-(void)hideKeyboard {
    [_urlField resignFirstResponder];
    [self hideCancelButton];
}

-(void)hideCancelButton {
    [_addrbar setItems:_addrItemsInactive animated:YES];
    
    [UIView beginAnimations:nil context:NULL];
    // TODO: calculate this numbers
    [_urlField setFrame:CGRectMake(12, 7, 260, 31)];
    [UIView commitAnimations];
    
}

-(void)cancel {
    [self hideKeyboard];
}


-(void)textFieldDidBeginEditing:(UITextField *)textField {
    [_addrbar setItems:_addrItemsActive animated:YES];
    
    [UIView beginAnimations:nil context:NULL];
    // TODO: calculate this numbers
    [_urlField setFrame:CGRectMake(12, 7, 230, 31)];
    [UIView commitAnimations];
}
-(void)textFieldDidEndEditing {
    [self hideKeyboard];
    [self openURL:_urlField.text];
}
-(BOOL)textFieldShouldEndEditing:(UITextField *)textField {
    return YES;
}
-(void)keyboardHiden:(NSNotification *)notification {
    [self hideCancelButton];
}

@end
