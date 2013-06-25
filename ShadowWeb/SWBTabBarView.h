//
//  SWBTabBarView.h
//  SWBuaWeb
//
//  Created by clowwindy on 11-6-10.
//  Copyright 2011年 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SWBTab.h"
#import "SWBNewTabButton.h"
#import "SWBTabView.h"

#define kMaxWidth 1024.0
#define kTabBarHeight 40

@protocol SWBTabBarDelegate <NSObject>

@required

-(void)tabBarViewNewTabButtonDidClick;
-(void)tabBarViewTabDidClose:(SWBTab *)tab;
-(void)tabBarViewTabDidMove:(SWBTab *)tab toIndex:(NSInteger)index;
-(void)tabBarViewTabDidSelect:(SWBTab *)tab;

@end


enum SWBTabBarAction {
    SWBTabBarActionNone = 0,
    SWBTabBarActionNew = 1,
    SWBTabBarActionClose = 2,
    SWBTabBarActionMoving = 3,
    SWBTabBarActionMoveEnded = 4,
    SWBTabBarActionDraggingTab = 5,
    SWBTabBarActionDragTabEnded = 6,
    SWBTabBarActionInit = 7
};

@interface SWBTabBarView : UIView <SWBTabViewDelegate> {
    NSMutableArray *tabViews;
    SWBNewTabButton *newTabButton;
    
    NSInteger currentMaxTag;
    CGFloat currentTabWidth;
    
    // 手指滚动时，偏移的坐标。松手后，此值将会归零
    CGFloat movingOffset;
    CGFloat lastWidth;
    
    // 拖动标签页
    CGFloat draggingTabLocationStartX;
    CGFloat draggingTabLocationCurrentX;
    NSInteger draggingIndexFrom;
    
    SWBTab *currentDraggingTab;
}

@property (nonatomic, weak) id<SWBTabBarDelegate> delegate;

//仅供初始化和读取
@property (nonatomic, strong) NSMutableArray *tabs;
@property (nonatomic, strong) SWBTab *currentTab;
//仅供初始化和读取
@property (nonatomic, assign) NSInteger firstLeftTab;
-(UIView *)aNewTabButton;

//按照tabs调整tabViews，也负责新建和关闭，不过算法假设一次要么添加，要么关闭，要么移动，并且只改变了一个标签页的状态；或者初始化
-(void)layoutTabsWithAction:(enum SWBTabBarAction)action animated:(BOOL)animated;

-(SWBTab *)newTab;
-(void)closeTab:(SWBTab *)tab animated:(BOOL)animated;
-(void)newTabButtonClicked;
-(void)setCurrentTabWithTag:(NSInteger)tag;
-(void)setTitleForTab:(NSInteger)tag title:(NSString *)theTitle;
//-(void)setPercentForTab:(NSInteger)tag percentage:(float)percentage;
-(void)setLoadingForTab:(NSInteger)tag loading:(BOOL)loading;

- (void)handlePanGesture:(UIGestureRecognizer *)gestureRecognizer;
- (void)handleLongPressGesture:(UIGestureRecognizer *)gestureRecognizer;

@end
