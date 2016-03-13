//
//  SWBWebViewContainer.m
//  AquaWeb
//
//  Created by clowwindy on 11-6-16.
//  Copyright 2011年 __MyCompanyName__. All rights reserved.
//

#import "SWBWebViewContainer.h"
#import "SWBAppDelegate.h"
//#import "WebView.h"
//#import "UIWebDocumentView.h"

@implementation SWBWebViewContainer

@synthesize delegate;

-(void)loadDefaults {
    cachedWebViews = [[NSMutableArray alloc] init];
    s = [[NSString alloc] initWithFormat:@"_setDraw%@:", [@"InWebThread" copy]];
}

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
        [self loadDefaults];
    }
    return self;
}

-(id)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        // Initialization code
        [self loadDefaults];
    }
    return self;
}

- (void)setNetworkIndicatorStatus {
    BOOL loading = NO;
    for (SWBWebView *webView in cachedWebViews) {
        loading |= webView.loading;
    }
    [appNetworkActivityIndicatorManager setSourceActivityStatusIsBusy:self busy:loading];
//    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:loading];
}

- (void)moveWebViewToCacheQueueEnd:(SWBWebView *)webView {
    // TODO
    if ([cachedWebViews containsObject:webView]) {
        [cachedWebViews removeObject:webView];
    }
    [cachedWebViews addObject:webView];
}

//- (void)progressEstimateChanged:(NSNotification*)theNotification {
//    // You can get the progress as a float with
//    // [[theNotification object] estimatedProgress], and then you
//    // can set that to a UIProgressView if you'd like.
//    // theProgressView is just an example of what you could do.
//    
////    [theProgressView setProgress:[[theNotification object] estimatedProgress]];
//    
//    NSLog(@"%@",[[theNotification object] estimatedProgress]);
//    
//    if ((int)[[theNotification object] estimatedProgress] == 1) {
////        theProgressView.hidden = TRUE;
//        // Hide the progress view. This is optional, but depending on where
//        // you put it, this may be a good idea.
//        // If you wanted to do this, you'd
//        // have to set theProgressView to visible in your
//        // webViewDidStartLoad delegate method,
//        // see Apple's UIWebView documentation.
//    }
//}

- (void)initAWebView:(SWBWebView *)webView {
    webView.backgroundColor = [UIColor scrollViewTexturedBackgroundColor];
//    cause crash on double-tap
    
    @try {
        SEL ss = NSSelectorFromString(s);
        
        if ([webView respondsToSelector:ss]) {
            NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:[UIWebView instanceMethodSignatureForSelector:ss]];
            BOOL setting = YES;
            [invocation setSelector:ss];
            [invocation setTarget:webView];
            [invocation setArgument:&setting atIndex:2];
            [invocation invoke];
//            [webView performSelector:ss withObject:YES];
        }
    }
    @catch (NSException *exception) {
        NSLog(@"%@", exception);
    }
    @finally {
        
    }
    
    webView.frame = CGRectMake(0, 0, self.bounds.size.width, self.bounds.size.height);
    webView.autoresizingMask = UIViewAutoresizingFlexibleHeight 
    | UIViewAutoresizingFlexibleWidth;
    webView.multipleTouchEnabled = YES;
    webView.scalesPageToFit = YES;
    webView.delegate = self;
    
//    UIWebDocumentView *documentView = [webView _documentView];
//    WebView *coreWebView = [documentView webView];
//    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(progressEstimateChanged:) name:@"WebViewProgressEstimateChangedNotification" object:coreWebView];
//    [coreWebView estimatedProgress
    
}
- (void)removeAWebView:(SWBWebView *)webView {
    webView.delegate = nil;
//    // fix memory leaks
//    [webView loadHTMLString:@"" baseURL:nil];
    [cachedWebViews removeObject:webView];
    if (webView.superview) {
        [webView removeFromSuperview];
    }
}

- (SWBWebView *)getANewWebView {
    NSInteger count = [cachedWebViews count];
    if (count >= kMaxCachedWebViews) {
        [self removeAWebView:[cachedWebViews objectAtIndex:0]];
    }
    SWBWebView *webView = [[SWBWebView alloc] init];
    [self initAWebView:webView];
    [cachedWebViews addObject:webView];
    
    return webView;
}

- (void)switchToWebViewWithWebView:(SWBWebView *)webView {
    [self moveWebViewToCacheQueueEnd:webView];
//    if (currentWebView) {
//        [currentWebView removeFromSuperview];
//    }
    if (currentWebView && currentWebView != webView) {
        // 让后台的网页不改变大小，以加快旋转和显示小工具的速度
        currentWebView.autoresizingMask = UIViewAutoresizingNone;
//        currentWebView.hidden = YES;
        @try {
            ((UIScrollView *)[[currentWebView subviews] objectAtIndex:0]).scrollsToTop = NO;
        }
        @catch (NSException *exception) {
        }
        @finally {
        }
    }
    if (webView.superview) {
        [self bringSubviewToFront:webView];
    } else {
//        webView.frame = CGRectZero;
        [self addSubview:webView];        
    }
//    webView.hidden = NO;
    @try {
        ((UIScrollView *)[[webView subviews] objectAtIndex:0]).scrollsToTop = YES;
    }
    @catch (NSException *exception) {
    }
    @finally {
    }
    currentWebView = webView;
    // 设置前台
    webView.frame = CGRectMake(0, 0, self.bounds.size.width, self.bounds.size.height);
    webView.autoresizingMask = UIViewAutoresizingFlexibleHeight 
    | UIViewAutoresizingFlexibleWidth;
}

- (void)newWebView:(NSInteger)tag {
    SWBWebView *webView = [self getANewWebView];
    webView.tag = tag;
    [self switchToWebViewWithWebView:webView];
    
    [delegate webViewContainerWebViewDidCreateNew:webView];
}

- (void)switchToWebView:(NSInteger)tag {
    SWBWebView *webView = [self webViewByTag:tag];
    if (currentWebView && currentWebView == webView) {
        // do not compare tags, because currentWebView may be released
        return;
    }
    [self switchToWebViewWithWebView:webView];
    
    [delegate webViewContainerWebViewDidSwitchToWebView:webView];
}

- (void)closeWebView:(NSInteger)tag {
    if (tag == currentWebView.tag) {
        currentWebView = nil;
    }
    [self removeAWebView:[self webViewByTag:tag]];
}

- (SWBWebView *)webViewByTag:(NSInteger)tag {
    for (SWBWebView *webView in cachedWebViews) {
        if (webView.tag == tag) {
            return webView;
        }
    }
    SWBWebView *webView = [self getANewWebView];
    webView.tag = tag;
    
    [delegate webViewContainerWebViewNeedToReload:webView tag:tag];
    
    return webView;
}

- (NSInteger)currentWebView {
    return currentWebView.tag;
}

- (SWBWebView *)currentSWBWebView {
    return currentWebView;
}

- (void)releaseBackgroundWebViews {
    NSInteger count = [cachedWebViews count];
    for (int i = 0; i < count - kMinCachedWebViews; i ++) {
        [(UIWebView *)[cachedWebViews objectAtIndex:0] removeFromSuperview];
        [cachedWebViews removeObjectAtIndex:0];
    }
}

- (void)removeBackgroundWebViewsFromSuperView {
    NSInteger count = [cachedWebViews count];
    for (int i = 0; i < count - kMinCachedWebViews; i ++) {
        [(UIWebView *)[cachedWebViews objectAtIndex:i] removeFromSuperview];
    }
}

-(void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error {
    [delegate webView:webView didFailLoadWithError:error];
    [self setNetworkIndicatorStatus];
}

-(BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType {
    if (delegate) {
        [delegate webView:webView shouldStartLoadWithRequest:request navigationType:navigationType];
    }
    return YES;
}

-(void)webViewDidFinishLoad:(UIWebView *)webView {
    [delegate webViewDidFinishLoad:webView];
    [self setNetworkIndicatorStatus];
}

-(void)webViewDidStartLoad:(UIWebView *)webView {
    [delegate webViewDidStartLoad:webView];
    [self setNetworkIndicatorStatus];
}

-(NSString *)titleForWebView:(SWBWebView *)webView {
    NSString *theTitle = [webView stringByEvaluatingJavaScriptFromString:@"document.title"];
    return theTitle;
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    // Drawing code
}
*/

@end
