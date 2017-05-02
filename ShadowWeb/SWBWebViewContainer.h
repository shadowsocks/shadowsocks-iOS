//
//  SWBWebViewContainer.h
//  AquaWeb
//
//  Created by clowwindy on 11-6-16.
//  Copyright 2011年 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SWBWebView.h"

#define kMaxCachedWebViews 10
#define kMinCachedWebViews 2

@protocol SWBWebViewContainerDelegate <UIWebViewDelegate>

@required

-(void)webViewContainerWebViewDidCreateNew:(SWBWebView *)webView;
-(void)webViewContainerWebViewDidSwitchToWebView:(SWBWebView *)webView;
-(void)webViewContainerWebViewNeedToReload:(SWBWebView *)webView tag:(NSInteger)tag;

@end

@interface SWBWebViewContainer : UIView <UIWebViewDelegate> {
    // 最旧的在0，最新的在末尾
    NSMutableArray *cachedWebViews;
    SWBWebView *currentWebView;
    NSString *s;
}

- (void)newWebView:(NSInteger)tag;
- (void)switchToWebView:(NSInteger)tag;
- (void)closeWebView:(NSInteger)tag;

- (SWBWebView *)webViewByTag:(NSInteger)tag;
- (NSInteger)currentWebView;

- (SWBWebView *)currentSWBWebView;

// 彻底释放，适合内存严重不足
- (void)releaseBackgroundWebViews;
// 仅从superview移除，可以节省部分内存
- (void)removeBackgroundWebViewsFromSuperView;

- (NSString *)titleForWebView:(SWBWebView *)webView;

//- (void)progressEstimateChanged:(NSNotification*)theNotification;

@property (nonatomic, weak) id<SWBWebViewContainerDelegate> delegate;

@end
