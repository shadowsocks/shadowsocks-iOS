//
//  WebViewController.m
//  OnionBrowser
//
//  Created by Mike Tigas on 2/25/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#include "err.h"

#import "WebViewController.h"
#import "AppDelegate.h"
#import "BookmarkTableViewController.h"
#import "SettingsViewController.h"
#import "Bookmark.h"
#import "BridgeTableViewController.h"
#import "ProxySettingsTableViewController.h"

static const CGFloat kNavBarHeight = 52.0f;
static const CGFloat kToolBarHeight = 44.0f;
static const CGFloat kLabelHeight = 14.0f;
static const CGFloat kMargin = 10.0f;
static const CGFloat kSpacer = 2.0f;
static const CGFloat kLabelFontSize = 12.0f;
static const CGFloat kAddressHeight = 26.0f;

static const NSInteger kNavBarTag = 1000;
static const NSInteger kAddressFieldTag = 1001;
static const NSInteger kAddressCancelButtonTag = 1002;
static const NSInteger kLoadingStatusTag = 1003;

static const Boolean kForwardButton = YES;
static const Boolean kBackwardButton = NO;

@interface WebViewController ()

@end

@implementation WebViewController

@synthesize myWebView = _myWebView,
            toolbar = _toolbar,
            backButton = _backButton,
            forwardButton = _forwardButton,
            toolButton = _toolButton,
            optionsMenu = _optionsMenu,
            bookmarkButton = _bookmarkButton,
            stopRefreshButton = _stopRefreshButton,
            pageTitleLabel = _pageTitleLabel,
            addressField = _addressField,
            currentURL = _currentURL,
            torStatus = _torStatus;
@synthesize addrItemsActive, addrItemsInactive, cancelButton;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        dontLoadURLNow = NO;
    }
    return self;
}

-(void)loadView {
    UIView *contentView = [[UIView alloc] initWithFrame:[[UIScreen mainScreen] applicationFrame]];
    self.view = contentView;
    CGRect webViewFrame = [[UIScreen mainScreen] applicationFrame];
    webViewFrame.origin.y = kNavBarHeight;
    webViewFrame.origin.x = 0;
    webViewFrame.size.height = webViewFrame.size.height - kToolBarHeight - kNavBarHeight;
    _myWebView = [[UIWebView alloc] initWithFrame:webViewFrame];
    _myWebView.backgroundColor = [UIColor whiteColor];
    _myWebView.scalesPageToFit = YES;
    _myWebView.contentScaleFactor = 3;
    _myWebView.autoresizingMask = (UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight);
    _myWebView.delegate = self;
    [self.view addSubview: _myWebView];
}

- (void)renderTorStatus: (NSString *)statusLine {
    // TODO: really needs cleanup / prettiness
    //       (turn into semi-transparent modal with spinner?)
    UILabel *loadingStatus = (UILabel *)[self.view viewWithTag:kLoadingStatusTag];
                                                                       
    _torStatus = [NSString stringWithFormat:@"%@\n%@",
                  _torStatus, statusLine];
    NSRange progress_loc = [statusLine rangeOfString:@"BOOTSTRAP PROGRESS="];
    NSRange progress_r = {
        progress_loc.location+progress_loc.length,
        2
    };
    NSString *progress_str = @"";
    if (progress_loc.location != NSNotFound)
        progress_str = [statusLine substringWithRange:progress_r];

    NSRange summary_loc = [statusLine rangeOfString:@" SUMMARY="];
    NSString *summary_str = @"";
    if (summary_loc.location != NSNotFound)
        summary_str = [statusLine substringFromIndex:summary_loc.location+summary_loc.length+1];
    NSRange summary_loc2 = [summary_str rangeOfString:@"\""];
    if (summary_loc2.location != NSNotFound)
        summary_str = [summary_str substringToIndex:summary_loc2.location];

    NSString *status = [NSString stringWithFormat:@"Connecting… This may take a minute.\n\nIf this takes longer than 60 seconds, please close and re-open the app to try connecting from scratch.\n\nIf this problem persists, you can try connecting via Tor bridges by pressing the \"options\" button below. Visit http://onionbrowser.com/help/ if you need help with bridges or if you continue to have issues.\n\n%@%%\n%@",
                            progress_str,
                            summary_str];
    loadingStatus.text = status;
   
}

-(void)loadURL: (NSURL *)navigationURL {
    // Remove the "connecting..." (initial tor load) overlay if it still exists.
    UIView *loadingStatus = [self.view viewWithTag:kLoadingStatusTag];
    if (loadingStatus != nil) {
        [loadingStatus removeFromSuperview];
    }

    AppDelegate *appDelegate = [[UIApplication sharedApplication] delegate];

    // Build request and go.
    _myWebView.delegate = self;
    _myWebView.scalesPageToFit = YES;
    NSMutableURLRequest *req = [NSMutableURLRequest requestWithURL:navigationURL];
    [req setHTTPShouldUsePipelining:appDelegate.usePipelining];
    [_myWebView loadRequest:req];

    _addressField.enabled = YES;
    _toolButton.enabled = YES;
    _stopRefreshButton.enabled = YES;
    _bookmarkButton.enabled = YES;
    [self updateButtons];
}


- (UIImage *)makeForwardBackButtonImage:(Boolean)whichButton {
    // Draws the vector image for the forward or back button. (see kForwardButton
    // and kBackwardButton for the "whichButton" values)
    CGFloat scale = [[UIScreen mainScreen] scale];
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    CGContextRef context = CGBitmapContextCreate(nil,28*scale,28*scale,8,0,
                                                 colorSpace,kCGImageAlphaPremultipliedLast);
    CFRelease(colorSpace);
    CGColorRef fillColor = [[UIColor blackColor] CGColor];
    CGContextSetFillColor(context, CGColorGetComponents(fillColor));
    
    CGContextBeginPath(context);
    if (whichButton == kForwardButton) {
        CGContextMoveToPoint(context, 20.0f*scale, 12.0f*scale);
        CGContextAddLineToPoint(context, 4.0f*scale, 4.0f*scale);
        CGContextAddLineToPoint(context, 4.0f*scale, 22.0f*scale);
    } else {
        CGContextMoveToPoint(context, 8.0f*scale, 12.0f*scale);
        CGContextAddLineToPoint(context, 24.0f*scale, 4.0f*scale);
        CGContextAddLineToPoint(context, 24.0f*scale, 22.0f*scale);
    }
    CGContextClosePath(context);
    CGContextFillPath(context);
    
    CGImageRef theCGImage = CGBitmapContextCreateImage(context);
    CGContextRelease(context);
    UIImage *buttonImage = [[UIImage alloc] initWithCGImage:theCGImage
                                                    scale:[[UIScreen mainScreen] scale]
                                              orientation:UIImageOrientationUp];
    CGImageRelease(theCGImage);
    return buttonImage;
}

- (void)viewDidLoad {
    [super viewDidLoad];

    // Set up toolbar.
    _toolbar = [[UIToolbar alloc] init];
    [_toolbar setTintColor:[UIColor blackColor]];
    _toolbar.frame = CGRectMake(0, self.view.frame.size.height - kToolBarHeight, self.view.frame.size.width, kToolBarHeight);
    _toolbar.autoresizingMask = UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleWidth;
    _toolbar.contentMode = UIViewContentModeBottom;
    UIBarButtonItem *space = [[UIBarButtonItem alloc]
                               initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace
                               target:nil
                               action:nil];
        
    _backButton = [[UIBarButtonItem alloc] initWithImage:[self makeForwardBackButtonImage:kBackwardButton]
                    style:UIBarButtonItemStylePlain
                    target:self
                    action:@selector(goBack)];
    _forwardButton = [[UIBarButtonItem alloc] initWithImage:[self makeForwardBackButtonImage:kForwardButton]
                    style:UIBarButtonItemStylePlain
                    target:self
                    action:@selector(goForward)];
    _toolButton = [[UIBarButtonItem alloc]
                      initWithBarButtonSystemItem:UIBarButtonSystemItemAction
                      target:self
                      action:@selector(openOptionsMenu)];
    _bookmarkButton = [[UIBarButtonItem alloc]
                   initWithBarButtonSystemItem:UIBarButtonSystemItemBookmarks
                   target:self
                   action:@selector(showBookmarks)];
    _stopRefreshButton = [[UIBarButtonItem alloc]
                    initWithBarButtonSystemItem:UIBarButtonSystemItemRefresh
                    target:self
                    action:@selector(stopLoading)];

    _forwardButton.enabled = NO;
    _backButton.enabled = NO;
    _stopRefreshButton.enabled = NO;
    _toolButton.enabled = YES;
    _bookmarkButton.enabled = NO;

    NSMutableArray *items = [[NSMutableArray alloc] init];
    [items addObject:_backButton];
    [items addObject:space];
    [items addObject:_forwardButton];
    [items addObject:space];
    [items addObject:_toolButton];
    [items addObject:space];
    [items addObject:_bookmarkButton];
    [items addObject:space];
    [items addObject:_stopRefreshButton];
    [_toolbar setItems:items animated:NO];
    
    [self.view addSubview:_toolbar];
    // (/toolbar)
    
    // Set up actionsheets (options menu, bookmarks menu)
    _optionsMenu = [[UIActionSheet alloc] initWithTitle:nil
                                               delegate:self
                                      cancelButtonTitle:@"Close"
                                 destructiveButtonTitle:nil
                                      otherButtonTitles:@"Bookmark Current Page", @"Proxy Settings", @"About", nil];
    // (/actionsheets)
    
    
    // Set up navbar
    CGRect navBarFrame = self.view.bounds;
    navBarFrame.size.height = kNavBarHeight;
    UIToolbar *navBar = [[UIToolbar alloc] initWithFrame:navBarFrame];
    navBar.tag = kNavBarTag;
    navBar.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    
    CGRect labelFrame = CGRectMake(kMargin, kSpacer, 
                                   navBar.bounds.size.width - 2*kMargin, kLabelHeight);
    UILabel *label = [[UILabel alloc] initWithFrame:labelFrame];
    label.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    label.text = @"";
    label.backgroundColor = [UIColor clearColor];
    label.font = [UIFont systemFontOfSize:12];
    label.textAlignment = UITextAlignmentCenter;
    
    [navBar setTintColor:[UIColor blackColor]];
    [label setTextColor:[UIColor whiteColor]];

    [navBar addSubview:label];
    _pageTitleLabel = label;
    
    // The address field is the same with as the label and located just below 
    // it with a gap of kSpacer
    CGRect addressFrame = CGRectMake(kMargin, kSpacer*2.0 + kLabelHeight, 
                                     labelFrame.size.width, kAddressHeight);
    UITextField *address = [[UITextField alloc] initWithFrame:addressFrame];
    
    address.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    address.borderStyle = UITextBorderStyleRoundedRect;
    address.font = [UIFont systemFontOfSize:17];
    address.keyboardType = UIKeyboardTypeURL;
    address.returnKeyType = UIReturnKeyGo;
    address.autocorrectionType = UITextAutocorrectionTypeNo;
    address.autocapitalizationType = UITextAutocapitalizationTypeNone;
    address.clearButtonMode = UITextFieldViewModeWhileEditing;
    address.delegate = self;
    address.tag = kAddressFieldTag;
//    [address addTarget:self 
//                action:@selector(loadAddress:event:) 
//      forControlEvents:UIControlEventEditingDidEndOnExit|UIControlEventEditingDidEnd];
    
    self.cancelButton = [[UIBarButtonItem alloc] initWithTitle:@"Cancel" style:UIBarButtonItemStyleBordered target:self action:@selector(addressBarCancel) ];
        
    self.addrItemsInactive = [NSMutableArray arrayWithObjects:[[UIBarButtonItem alloc] initWithCustomView:address], [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil], nil];
    self.addrItemsActive = [NSMutableArray arrayWithArray:addrItemsInactive];
    [addrItemsActive addObject:cancelButton];
    
    [navBar setItems:addrItemsInactive];
    [navBar setBarStyle:UIBarStyleBlack];
    
    _addressField = address;
    _addressField.enabled = YES;
    [self.view addSubview:navBar];
    // (/navbar)
    
    AppDelegate *appDelegate = [[UIApplication sharedApplication] delegate];
    if (appDelegate.doPrepopulateBookmarks){
        [self prePopulateBookmarks];
    }
}

-(void)viewDidAppear:(BOOL)animated {
    if ([ProxySettingsTableViewController settingsAreNotComplete]) {
        [self showSettings];
    }
}

-(void) prePopulateBookmarks {
    AppDelegate *appDelegate = [[UIApplication sharedApplication] delegate];
    
    NSManagedObjectContext *context = [appDelegate managedObjectContext];
    
    NSError *error = nil;
    if (![context save:&error]) {
        NSLog(@"Error adding bookmarks: %@", error);
    }
}


- (void)viewDidUnload {
    [super viewDidUnload];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    // Allow all four orientations on iPad.
    // Disallow upside-down for iPhone.
    return (IS_IPAD) || (interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
}

# pragma mark -
# pragma mark WebView behavior

- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType {
    [self updateAddress:request];
    return YES;
}

 - (void)webViewDidStartLoad:(UIWebView *)webView {
    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
    [self updateButtons];
}

- (void)webViewDidFinishLoad:(UIWebView *)webView {
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
    [self updateButtons];
    [self updateTitle:webView];
    NSURLRequest* request = [webView request];
    [self updateAddress:request];
}

- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error {
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
    [self updateButtons];
    [self informError:error];
    #ifdef DEBUG
        NSString* errorString = [NSString stringWithFormat:@"error %@",
                                 error.localizedDescription];
        NSLog(@"[WebViewController] Error: %@", errorString);
    #endif
}

- (void)informError:(NSError *)error {
    if ([error.domain isEqualToString:@"NSOSStatusErrorDomain"] &&
        (error.code == -9807 || error.code == -9812)) {
        // Invalid certificate chain; valid cert chain, untrusted root

        UIAlertView* alertView = [[UIAlertView alloc]
                                  initWithTitle:@"SSL Error"
                                  message:@"Certificate chain is invalid. Either the site's SSL certificate is self-signed or the certificate was signed by an untrusted authority."
                                  delegate:nil
                                  cancelButtonTitle:@"Cancel"
                                  otherButtonTitles:@"Continue",nil];
        alertView.delegate = self;
        [alertView show];

    } else if ([error.domain isEqualToString:(NSString *)kCFErrorDomainCFNetwork] ||
               [error.domain isEqualToString:@"NSOSStatusErrorDomain"]) {
        NSString* errorDescription;
        
        if (error.code == kCFSOCKS5ErrorBadState) {
            errorDescription = @"Could not connect to the server. Either the domain name is incorrect, the server is inaccessible, or the Tor circuit was broken.";
        } else if (error.code == kCFHostErrorHostNotFound) {
            errorDescription = @"The server could not be found";
        } else {
            errorDescription = [NSString stringWithFormat:@"An error occurred: %@",
                                error.localizedDescription];
        }
        UIAlertView* alertView = [[UIAlertView alloc]
                                  initWithTitle:@"Cannot Open Page"
                                  message:errorDescription delegate:nil
                                  cancelButtonTitle:@"OK"
                                  otherButtonTitles:nil];
        [alertView show];
    }
    #ifdef DEBUG
    else {
        NSLog(@"[WebViewController] uncaught error: %@", [error localizedDescription]);
        NSLog(@"\t -> %@", error.domain);
    }
    #endif
}

- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex {
    if (buttonIndex == 1) {
        // "Continue anyway" for SSL cert error
        AppDelegate *appDelegate = [[UIApplication sharedApplication] delegate];

        // Assumung URL in address bar is the one that caused this error.
        NSURL *url = [NSURL URLWithString:_currentURL];
        NSString *hostname = url.host;
        [appDelegate.sslWhitelistedDomains addObject:hostname];

        UIAlertView* alertView = [[UIAlertView alloc]
                                  initWithTitle:@"Whitelisted Domain"
                                  message:[NSString stringWithFormat:@"SSL certificate errors for '%@' will be ignored for the rest of this session.", hostname] delegate:nil 
                                  cancelButtonTitle:@"OK"
                                  otherButtonTitles:nil];
        [alertView show];

        // Reload (now that we have added host to whitelist)
        [self loadURL:url];
    }
}



# pragma mark -
# pragma mark Address Bar

- (void)addressBarCancel {
    _addressField.text = _currentURL;
    dontLoadURLNow = YES;
    [_addressField resignFirstResponder];
    dontLoadURLNow = NO;
}
- (BOOL)textFieldShouldReturn:(UITextField *)textField {
	[textField resignFirstResponder];
	return YES;
}

- (void)textFieldDidBeginEditing:(UITextField *)textField {
    // Stop loading if we are loading a page
    [_myWebView stopLoading];
    
    // Move a "cancel" button into the nav bar a la Safari.
    UIToolbar *navBar = (UIToolbar *)[self.view viewWithTag:kNavBarTag];
        
    [navBar setItems:addrItemsActive animated:YES];
    
    
    [UIView beginAnimations:nil context:NULL];
    [_addressField setFrame:CGRectMake(kMargin, kSpacer*2.0 + kLabelHeight,
                                       navBar.bounds.size.width - 2*kMargin - 70, kAddressHeight)];
    [UIView commitAnimations];
}

- (void)textFieldDidEndEditing:(UITextField *)textField {
    if (!dontLoadURLNow) {
        [self loadAddress:nil event:nil];
    }
    
    UIToolbar *navBar = (UIToolbar *)[self.view viewWithTag:kNavBarTag];
    
    
    [navBar setItems:addrItemsInactive animated:YES];
    
    [UIView beginAnimations:nil context:NULL];
    [_addressField setFrame:CGRectMake(kMargin, kSpacer*2.0 + kLabelHeight,
                                       navBar.bounds.size.width - 2*kMargin, kAddressHeight)];
    [UIView commitAnimations];
}

# pragma mark -
# pragma mark Options Menu action sheet

- (void)openOptionsMenu {
        [_optionsMenu showFromToolbar:_toolbar];
//    }
}
- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (actionSheet == _optionsMenu) {
        if (buttonIndex == 0) {
            ////////////////////////////////////////////////////////
            // Add To Bookmarks
            ////////////////////////////////////////////////////////
            [self addCurrentAsBookmark];
        } else if (buttonIndex == 1) {
            [self showSettings];
        } else if (buttonIndex == 2) {
            [self loadURL:[NSURL URLWithString:@"https://github.com/shadowsocks/shadowsocks-iOS/blob/master/LICENSE"]];
        } else {
            // close
        }
    }
}

-(void) showSettings {
    ProxySettingsTableViewController *settingsController = [[ProxySettingsTableViewController alloc] initWithStyle:UITableViewStyleGrouped];
    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:settingsController];
    nav.navigationBar.tintColor = [UIColor blackColor];
    nav.navigationBar.barStyle = UIBarStyleBlackOpaque;
    [self presentModalViewController:nav animated:YES];
}

# pragma mark -
# pragma mark Toolbar/navbar behavior

- (void)goForward {
    [_myWebView goForward];
    [self updateTitle:_myWebView];
    [self updateAddress:[_myWebView request]];
    [self updateButtons];
}
- (void)goBack {
    [_myWebView goBack];
    [self updateTitle:_myWebView];
    [self updateAddress:[_myWebView request]];
    [self updateButtons];
}
- (void)stopLoading {
    [_myWebView stopLoading];
    [self updateTitle:_myWebView];
    if (!_addressField.isEditing) {
        _addressField.text = _currentURL;
    }
    [self updateButtons];
}
- (void)reload {
    [_myWebView reload];
    [self updateButtons];
}

- (void)updateButtons
{
    _forwardButton.enabled = _myWebView.canGoForward;
    _backButton.enabled = _myWebView.canGoBack;
    if (_myWebView.loading) {
        _stopRefreshButton = nil;
        _stopRefreshButton = [[UIBarButtonItem alloc]
                              initWithBarButtonSystemItem:UIBarButtonSystemItemStop
                              target:self
                              action:@selector(stopLoading)];
    } else {
        _stopRefreshButton = nil;
        _stopRefreshButton = [[UIBarButtonItem alloc]
                              initWithBarButtonSystemItem:UIBarButtonSystemItemRefresh
                              target:self
                              action:@selector(reload)];
    }
    _stopRefreshButton.enabled = YES;
    NSMutableArray *items = [[NSMutableArray alloc] init];
    UIBarButtonItem *space = [[UIBarButtonItem alloc]
                              initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace
                              target:nil
                              action:nil];
    [items addObject:_backButton];
    [items addObject:space];
    [items addObject:_forwardButton];
    [items addObject:space];
    [items addObject:_toolButton];
    [items addObject:space];
    [items addObject:_bookmarkButton];
    [items addObject:space];
    [items addObject:_stopRefreshButton];
    [_toolbar setItems:items animated:NO];

}

- (void)updateTitle:(UIWebView*)aWebView
{
    NSString* pageTitle = [aWebView stringByEvaluatingJavaScriptFromString:@"document.title"];
    _pageTitleLabel.text = pageTitle; 
}

- (void)updateAddress:(NSURLRequest*)request {
    NSURL* url = [request mainDocumentURL];
    NSString* absoluteString;
    
    if ((url != nil) && [[url scheme] isEqualToString:@"file"]) {
        // Faked local URLs
        if ([[url absoluteString] rangeOfString:@"startup.html"].location != NSNotFound) {
            absoluteString = @"onionbrowser:start";
        }
        else if ([[url absoluteString] rangeOfString:@"about.html"].location != NSNotFound) {
            absoluteString = @"onionbrowser:about";
        } else {
            absoluteString = @"";
        }
    } else {
        // Regular ol' web URL.
        absoluteString = [url absoluteString];
    }
    
    if (![absoluteString isEqualToString:_currentURL]){
        _currentURL = absoluteString;
        if (!_addressField.isEditing) {
            _addressField.text = absoluteString;
        }
    }
}

- (void)loadAddress:(id)sender event:(UIEvent *)event {
    NSString* urlString = _addressField.text;
    NSURL* url = [NSURL URLWithString:urlString];
    if(!url.scheme)
    {
        NSString *absUrl = [NSString stringWithFormat:@"http://%@", urlString];
        url = [NSURL URLWithString:absUrl];
    }
    _currentURL = [url absoluteString];
    [self loadURL:url];
}

- (void) addCurrentAsBookmark {
    if ((_currentURL != nil) && ![_currentURL isEqualToString:@""]) {
        AppDelegate *appDelegate = [[UIApplication sharedApplication] delegate];
        NSFetchRequest *request = [[NSFetchRequest alloc] init];
        NSEntityDescription *entity = [NSEntityDescription entityForName:@"Bookmark" inManagedObjectContext:appDelegate.managedObjectContext];
        [request setEntity:entity];
        
        NSError *error = nil;
        NSUInteger numBookmarks = [appDelegate.managedObjectContext countForFetchRequest:request error:&error];
        if (error) {
            // error state?
        }
        Bookmark *bookmark = (Bookmark *)[NSEntityDescription insertNewObjectForEntityForName:@"Bookmark" inManagedObjectContext:appDelegate.managedObjectContext];
        
        NSString *pageTitle = [_myWebView stringByEvaluatingJavaScriptFromString:@"document.title"];
        [bookmark setTitle:pageTitle];
        [bookmark setUrl:_currentURL];
        [bookmark setOrder:numBookmarks];
        
        NSError *saveError = nil;
        if (![appDelegate.managedObjectContext save:&saveError]) {
            NSLog(@"Error saving bookmark: %@", saveError);
        }

        UIAlertView* alertView = [[UIAlertView alloc]
                                  initWithTitle:@"Add Bookmark"
                                  message:[NSString stringWithFormat:@"Added '%@' %@ to bookmarks.",
                                           pageTitle, _currentURL]
                                  delegate:nil
                                  cancelButtonTitle:@"OK"
                                  otherButtonTitles:nil];
        alertView.delegate = self;
        [alertView show];
    } else {
        UIAlertView* alertView = [[UIAlertView alloc]
                                  initWithTitle:@"Add Bookmark"
                                  message:@"Can't bookmark a (local) page with no URL."
                                  delegate:nil
                                  cancelButtonTitle:@"OK"
                                  otherButtonTitles:nil];
        alertView.delegate = self;
        [alertView show];
    }
}

-(void)showBookmarks {
    BookmarkTableViewController *bookmarksVC = [[BookmarkTableViewController alloc] initWithStyle:UITableViewStylePlain];
    UINavigationController *bookmarkNavController = [[UINavigationController alloc]
                                                     initWithRootViewController:bookmarksVC];
    
    AppDelegate *appDelegate = [[UIApplication sharedApplication] delegate];
    
    NSManagedObjectContext *context = [appDelegate managedObjectContext];
    
    bookmarksVC.managedObjectContext = context;
    
    [self presentModalViewController:bookmarkNavController animated:YES];
}

@end
