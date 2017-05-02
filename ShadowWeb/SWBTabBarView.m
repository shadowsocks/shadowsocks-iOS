//
//  SWBTabBarView.m
//  SWBuaWeb
//
//  Created by clowwindy on 11-6-10.
//  Copyright 2011年 __MyCompanyName__. All rights reserved.
//

#import "SWBTabBarView.h"
//#import "SWBuaWebAppDelegate.h"

#define kTabBarMinTabWidth 120
#define kTabBarMaxTabWidth 280
#define kTabBarTabInset 20
#define kTabBarNewTabButtonWidth 40

#define kTabBarTopColor 0.85
#define kTabBarBottomColor 0.85

#define kTabBarOverflowTabAlpha 0.3

#define kTabBarDraggingTabAlpha 0.5

//#define kTabBarLongPressDraggingOffsetThreshold 10

@implementation SWBTabBarView

@synthesize delegate, tabs, currentTab, firstLeftTab;

-(UIView *)aNewTabButton {
    return newTabButton;
}

- (void)loadDefaults {
    self.clipsToBounds = YES;
    currentMaxTag = 0;
    
    tabs = [[NSMutableArray alloc] init];
    tabViews = [[NSMutableArray alloc] init];
    newTabButton = [[SWBNewTabButton alloc] initWithFrame:CGRectMake(0, 0, 40, 40)];
    [newTabButton addTarget:self action:@selector(newTabButtonClicked) forControlEvents:UIControlEventTouchUpInside];
    [self addSubview:newTabButton];
    [newTabButton setAccessibilityLabel:NSLocalizedString(@"Open New Tab", @"")];
    
    // init gestures
    UIPanGestureRecognizer *panGestureRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handlePanGesture:)];
    
    [self addGestureRecognizer:panGestureRecognizer];
    //    [self addGestureRecognizer:longPressGestureRecognizer];
    
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(settingsChanged) name:NSUserDefaultsDidChangeNotification object:nil];
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



// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    // Drawing code
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    //    CGContextClipToRect(context, rect);
    CGFloat width = self.bounds.size.width;
    
    CGGradientRef myGradient;
    CGColorSpaceRef myColorspace = CGColorSpaceCreateDeviceRGB();
    size_t num_locations = 2;
    CGFloat locations[2] = { 0.0, 1.0 };
    CGFloat components[8] = {
        kTabBarTopColor, kTabBarTopColor, kTabBarTopColor, 1.0,
        kTabBarBottomColor, kTabBarBottomColor, kTabBarBottomColor, 1.0 };
    
    
    myGradient = CGGradientCreateWithColorComponents (myColorspace, components,
                                                      locations, num_locations);
    
    CGPoint myStartPoint, myEndPoint;
    myStartPoint.x = 0;
    myStartPoint.y = 0;
    myEndPoint.x = 0;
    myEndPoint.y = kTabBarHeight;
    CGContextDrawLinearGradient(context, myGradient, myStartPoint,
                                myEndPoint,
                                kCGGradientDrawsAfterEndLocation);
    
    CGContextSetLineWidth(context, 1);
    
    CGContextMoveToPoint(context, 0, 0);
    CGContextSetRGBStrokeColor(context, 0.2, 0.2, 0.2, 1);
    CGContextAddLineToPoint(context, width, 0);
    CGContextDrawPath(context, kCGPathStroke);
    
//    CGContextMoveToPoint(context, 0, 1);
//    CGContextSetRGBStrokeColor(context, 1, 1, 1, 1);
//    CGContextAddLineToPoint(context, width, 1);
//    CGContextDrawPath(context, kCGPathStroke);
    
    CGGradientRelease(myGradient);
    CGColorSpaceRelease(myColorspace);
}

#pragma mark:tab layout

-(SWBTabView *)tabViewByTag:(NSInteger)tag {
    for (SWBTabView *tabView in tabViews) {
        if (tabView.tag == tag) {
            return tabView;
        }
    }
    return nil;
}

-(SWBTab *)tabByTag:(NSInteger)tag {
    for (SWBTab *tab in tabs) {
        if (tab.tag == tag) {
            return tab;
        }
    }
    return nil;
}

-(void)moveNewTabButtonToTop {
    if ([self.subviews indexOfObject: newTabButton] != [self.subviews count] - 1) {
        [newTabButton removeFromSuperview];
        [self addSubview:newTabButton];
    }
    
}

// 调整所有标签页的上下顺序
-(void)reorderTabViews {
    SWBTabView *currentTabView = nil;
    SWBTabView *lastTabView = nil;
    NSArray *s_subviews = self.subviews;
    SWBTabView *currentDraggingTabView = nil;
    BOOL startToSwap = NO;
    
    if (currentDraggingTab != nil) {
        currentDraggingTabView = [self tabViewByTag:currentDraggingTab.tag];
        
        [newTabButton removeFromSuperview];
        [self insertSubview:newTabButton belowSubview:currentDraggingTabView];
    } else {
        [self moveNewTabButtonToTop];
    }
    
    for (int i = [tabViews count] - 1; i >= 0; i--) {
        SWBTabView *tabView = tabViews[i];
        if (tabView == currentDraggingTabView || tabView.superview == nil) {
            continue;
        }
        
        if (tabView.tag == currentTab.tag) {
            currentTabView = tabView;
        }
        
        // 一点优化，只有当需要调换的时候才调换
        // 这个算法依然存在改进的空间，比如可以通过插入的方法
        if (currentDraggingTabView || startToSwap || (lastTabView && currentTabView != tabView && [s_subviews indexOfObject:lastTabView] > [s_subviews indexOfObject:tabView])) {
            startToSwap = YES;
            [tabView removeFromSuperview];
            //            [self addSubview:tabView];
            [self insertSubview:tabView belowSubview:newTabButton];
        }
        lastTabView = tabView;
        
    }
    
    // 将选中的标签页移动到最上
    
    if (currentTabView && currentDraggingTabView != currentTabView) {
        [currentTabView removeFromSuperview];
        [self addSubview:currentTabView];
        [self insertSubview:currentTabView belowSubview:newTabButton];
    }
    
}

-(void)initANewTabView:(SWBTabView *)tabView {
    tabView.contentMode = UIViewContentModeRedraw;
    [self addSubview:tabView];
    [tabViews addObject:tabView];
    [tabView addTarget:self action:@selector(tabClicked:) forControlEvents:UIControlEventTouchUpInside];
    tabView.delegate = self;
    UILongPressGestureRecognizer *longPressGestureRecognizer = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(handleLongPressGesture:)];
    //    [longPressGestureRecognizer setCancelsTouchesInView:NO];
    [tabView addGestureRecognizer:longPressGestureRecognizer];
    
    // TODO
//    BOOL showEnd = [appSettingsManager showEndOfTheTitle];
    BOOL showEnd = NO;
    tabView.titleLabel.lineBreakMode = showEnd? NSLineBreakByTruncatingMiddle:NSLineBreakByTruncatingTail;
}

-(void)removeATabView:(SWBTabView *)tabView {
    [tabView removeTarget:self action:@selector(tabClicked:) forControlEvents:UIControlEventTouchUpInside];
    [tabView removeFromSuperview];
    [tabViews removeObject:tabView];
    //    [tabView removeGestureRecognizer: [[tabView gestureRecognizers] objectAtIndex:0]];
    tabView.delegate = nil;
}

// 根据横坐标计算这是第几个标签页的位置
-(NSInteger)indexForPosition:(CGFloat)position {
    return position / currentTabWidth + firstLeftTab;
}

-(void)layoutTabsWithAction:(enum SWBTabBarAction)action animated:(BOOL)animated {
#ifdef DEBUG
//    NSLog(@"layoutTabsWithAction");
#endif
    int tabCount = [tabs count];
    int visibleTabCount = 0;
    
    CGFloat width = self.bounds.size.width;
    CGFloat height = self.bounds.size.height;
    
    CGFloat xOffset = movingOffset;
    
    CGFloat tabWidth;
    if (tabCount != 0) {
        tabWidth = (width - kTabBarNewTabButtonWidth) / tabCount;
        if (tabWidth < kTabBarMinTabWidth) {
            visibleTabCount = (width - kTabBarNewTabButtonWidth) / kTabBarMinTabWidth;
            tabWidth = (width - kTabBarNewTabButtonWidth) / visibleTabCount;
        } else if(tabWidth > kTabBarMaxTabWidth) {
            tabWidth = kTabBarMaxTabWidth;
            visibleTabCount = tabCount;
        } else {
            visibleTabCount = tabCount;
        }
    } else {
        tabWidth = kTabBarMaxTabWidth;
    }
    currentTabWidth = tabWidth;
    
    // 拖动结束后，将xOffset转换为firstLeftTab；关闭标签页和旋转后，也需要重新计算
    if (action == SWBTabBarActionMoveEnded || action == SWBTabBarActionClose || action == SWBTabBarActionNone) {
        firstLeftTab = firstLeftTab - (xOffset - tabWidth / 2) / tabWidth;
        if (firstLeftTab < 0) {
            firstLeftTab = 0;
        } else if(firstLeftTab > tabCount - visibleTabCount) {
            firstLeftTab = tabCount - visibleTabCount;
        }
        xOffset = 0;
    }
    // 新建标签页后，滚动到最右边
    else if (action == SWBTabBarActionNew) {
        if (tabCount > visibleTabCount) {
            firstLeftTab = tabCount - visibleTabCount;
        }
    }
    
    xOffset -= firstLeftTab * tabWidth;
    
    
    if (xOffset > 0) {
        // 如果偏移小于最左边，将多出来的拖动距离减半
        if(action == SWBTabBarActionMoving) {
            xOffset /= 2;
        } else {
            xOffset = 0;
        }
        // 1/(x+1)的积分
        //        xOffset = 200 * log1pf(xOffset / 200);
#ifdef DEBUG
//        NSLog(@"%f", xOffset);
#endif
    } else if(xOffset + tabWidth * tabCount < visibleTabCount * tabWidth) {
        // 如果偏移多于最右边，将多出来的距离减半
        CGFloat overflow = visibleTabCount * tabWidth - (tabCount * tabWidth + xOffset);
#ifdef DEBUG
//        NSLog(@"%f", overflow);
#endif
        if(action == SWBTabBarActionMoving) {
            xOffset = xOffset + overflow / 2;
        } else {
            xOffset = xOffset + overflow;
        }
        
        //        xOffset = (width - kTabBarNewTabButtonWidth - (xOffset + tabWidth * tabCount)) / 2 + tabCount * tabWidth;
    }
    
    if (action == SWBTabBarActionInit) {   
        for (int i = 0; i < visibleTabCount; i++) {
            SWBTabView *tabView = [[SWBTabView alloc] initWithFrame:CGRectMake((int)(xOffset + i * tabWidth - kTabBarTabInset / 2), 0, tabWidth + kTabBarTabInset, height)];
            tabView.tag = i;
            [self initANewTabView:tabView];
        }
    }
    
    SWBTabView *tabViewToChange;
    if (action == SWBTabBarActionNew) {
        tabViewToChange = [[SWBTabView alloc] initWithFrame:CGRectMake((int)(xOffset + (tabCount - 1) * tabWidth - kTabBarTabInset / 2), -height, tabWidth + kTabBarTabInset, height)];
        tabViewToChange.tag = [(SWBTab *)tabs[(tabCount - 1)] tag];
        [self initANewTabView:tabViewToChange];
    }
    
    // 调整正在被拖的标签页的位置
    
    if (action == SWBTabBarActionDraggingTab){
        CGFloat draggingTabOffset = draggingTabLocationCurrentX - draggingTabLocationStartX;
        CGFloat draggingTabViewX = xOffset + (draggingIndexFrom * tabWidth - kTabBarTabInset / 2);
        SWBTabView *currentTabView = [self tabViewByTag:currentDraggingTab.tag];
        currentTabView.frame = CGRectMake(draggingTabViewX + draggingTabOffset, 0, tabWidth + kTabBarTabInset, height);
    }
    
    if (animated) {
        [UIView beginAnimations:@"layoutTabs" context:NULL];
        
        // 进行额外的动画起始化设置
    }
    
    // 设置所有tabview的位置
    if (action == SWBTabBarActionNone || action == SWBTabBarActionNew || action == SWBTabBarActionClose || action == SWBTabBarActionMoving || action == SWBTabBarActionMoveEnded || action == SWBTabBarActionDragTabEnded) {
        int tabViewCount = [tabViews count];
        for (int i = 0; i < tabViewCount; i++) {
            SWBTabView *tabView = tabViews[i];
            tabView.frame = CGRectMake((int)(xOffset + i * tabWidth - kTabBarTabInset / 2), 0, tabWidth + kTabBarTabInset, height);
        }
    }
    
    // 设置除了被拖的标签页之外所有tabview的位置
    if (action == SWBTabBarActionDraggingTab) {
        int tabViewCount = [tabViews count];
        for (int i = 0; i < tabViewCount; i++) {
            SWBTabView *tabView = tabViews[i];
            if (tabView.tag != currentDraggingTab.tag) {
                tabView.frame = CGRectMake((int)(xOffset + i * tabWidth - kTabBarTabInset / 2), 0, tabWidth + kTabBarTabInset, height);
            }
        }
    }
    
    // 改变右边溢出的标签的透明度
    if (action == SWBTabBarActionMoving || action == SWBTabBarActionMoveEnded || action == SWBTabBarActionDraggingTab || action == SWBTabBarActionDragTabEnded || action == SWBTabBarActionClose || action == SWBTabBarActionNew || action == SWBTabBarActionNone){
        //        if (action == SWBTabBarActionMoving) {
        [UIView beginAnimations:@"tabbar change alpha" context:NULL];
        //        }
        int tabViewCount = [tabViews count];
        for (int i = 0; i < tabViewCount; i++) {
            SWBTabView *tabView = tabViews[i];
            if (tabView.tag != currentDraggingTab.tag) {
                if (tabView.frame.origin.x + tabView.frame.size.width / 2 > width - kTabBarNewTabButtonWidth) {
                    tabView.alpha = kTabBarOverflowTabAlpha;
                } else {
                    tabView.alpha = 1;
                }
            }
        }
        //        if (action == SWBTabBarActionMoving) {
        [UIView commitAnimations];
        //        }
    }
    
    //移动new tab按钮
    if (action == SWBTabBarActionNew || action == SWBTabBarActionClose || action == SWBTabBarActionInit || action == SWBTabBarActionNone) {
        // 延长按钮宽度
        CGFloat newTabButtonWidth = width - visibleTabCount * tabWidth;
        
        newTabButton.frame = CGRectMake(visibleTabCount * tabWidth, 0, newTabButtonWidth, self.bounds.size.height);
    }
    
    //将屏幕外的tabview隐藏
    {
        BOOL tabViewAdded = NO;
        int tabViewCount = [tabViews count];
        for (int i = 0; i < tabViewCount; i++) {
            SWBTabView *tabView = tabViews[i];
            if (tabView.frame.origin.x + tabView.frame.size.width < 0 || 
                tabView.frame.origin.x > width) {
                //                tabView.hidden = YES;
                [tabView removeFromSuperview];
            } else {
                //                tabView.hidden = NO;
                if (!tabView.superview) {
                    [self addSubview:tabView];
                    tabViewAdded = YES;
                } 
            }
        }
        if (tabViewAdded) {
            [self reorderTabViews];
        }
    }
    
    if (action == SWBTabBarActionDraggingTab) {
        [self tabViewByTag: currentDraggingTab.tag].alpha = kTabBarDraggingTabAlpha;
    } else if (action == SWBTabBarActionDragTabEnded) {
        [self tabViewByTag: currentDraggingTab.tag].alpha = 1;
    }
    
    
    if (animated) {
        [UIView commitAnimations];
    }
    
    //    [self moveNewTabButtonToTop];
}

-(void)layoutSubviews {
    [super layoutSubviews];
    
    CGFloat newWidth = self.bounds.size.width;
    if (newWidth != lastWidth) {
        [self layoutTabsWithAction:SWBTabBarActionNone animated:NO];
    }
    lastWidth = newWidth;
}

#pragma mark tabs handling

-(NSInteger)getNewTag {
    return currentMaxTag++;
}


-(SWBTab *)newTab{
    SWBTab *tab = [[SWBTab alloc] initWithTag:[self getNewTag]];
    [tabs addObject:tab];
    [self layoutTabsWithAction:SWBTabBarActionNew animated:YES];
    return tab;
}

-(void)closeTab:(SWBTab *)tab animated:(BOOL)animated {
    SWBTabView *tabView = [self tabViewByTag:tab.tag];
    
    // 如果关闭的是当前标签页，选中下一个标签页，如果右边没有，选中左边的
    if (currentTab == tab) {
        NSInteger index = [tabs indexOfObject:tab];
        if ([tabs count] != 1) {
            if (index == [tabs count] - 1) {
                // 如果就是最后一个，选左边的
                if (index != 0) {
                    self.currentTab = tabs[(index - 1)];
                }
            } else {
                self.currentTab = tabs[(index + 1)];
            }
        } else {
            self.currentTab = nil;
        }
        
    }
    
    [tabs removeObject:tab];
    [self removeATabView:tabView];
    
    [self layoutTabsWithAction:SWBTabBarActionClose animated:YES];
    
    [delegate tabBarViewTabDidClose:tab];
    
    
}

-(void)setCurrentTab:(SWBTab *)newCurrentTab {
    if (newCurrentTab == currentTab) {
        return;
    }
    if (newCurrentTab) {
        //TODO: set old current tab to a non-top status
        for (int i = 0; i < [tabs count]; i++) {
            SWBTab *tab = tabs[i];
            if (tab == currentTab) {
                for (SWBTabView *tabView in tabViews) {
                    if (tabView.tag == tab.tag) {
                        tabView.focused = NO;
                        break;
                    }
                }
            } else if(tab == newCurrentTab) {
                //            SWBTabView *tabViewFound = nil;
                for (SWBTabView *tabView in tabViews) {
                    if (tabView.tag == tab.tag) {
                        tabView.focused = YES;
                        //                    tabViewFound = tabView;
                        break;
                    }
                }
            }
        }

    }    
    currentTab = newCurrentTab;
    
    [self reorderTabViews];
    if (newCurrentTab) {
        [delegate tabBarViewTabDidSelect:currentTab];
    }
}

-(void)setCurrentTabWithTag:(NSInteger)tag {
    [self setCurrentTab:[self tabByTag:tag]];
}

-(void)newTabButtonClicked {
    [delegate tabBarViewNewTabButtonDidClick];
}

-(void)tabClicked:(id)sender {
    SWBTabView *tabView = sender;
    self.currentTab = [self tabByTag:tabView.tag];
}

-(void)tabViewDidClickCloseButton:(id)sender {
    SWBTabView *tabView = sender;
    SWBTab *tab = [self tabByTag:tabView.tag];
    [self closeTab:tab animated:YES];
}

#pragma mark gesture handling



- (void)handlePanGesture:(UIGestureRecognizer *)gestureRecognizer {
    
    CGPoint point = [(UIPanGestureRecognizer *)gestureRecognizer translationInView:self];
    UIGestureRecognizerState state = [(UIPanGestureRecognizer *)gestureRecognizer state];
    if (state == UIGestureRecognizerStateBegan || state == UIGestureRecognizerStateChanged) {
        movingOffset = point.x;
        [self layoutTabsWithAction:SWBTabBarActionMoving animated:NO];
    } else if (state == UIGestureRecognizerStateEnded || state == UIGestureRecognizerStateCancelled) {
        [self layoutTabsWithAction:SWBTabBarActionMoveEnded animated:YES];
        movingOffset = 0;
    }
#ifdef DEBUG
//    NSLog(@"pan %@", gestureRecognizer.view);
//    NSLog(@"%f", point.x);
#endif
}

- (void)handleLongPressGesture:(UIGestureRecognizer *)gestureRecognizer {
    SWBTabView *tabView = (SWBTabView *)gestureRecognizer.view;
    currentDraggingTab = [self tabByTag:tabView.tag];
    
    CGFloat currentPointX = [(UILongPressGestureRecognizer *)gestureRecognizer locationInView:self].x;
    if (gestureRecognizer.state == UIGestureRecognizerStateBegan) {
        // 记录开始拖动时的信息
        draggingTabLocationStartX = currentPointX;
        draggingIndexFrom = [tabs indexOfObject:currentDraggingTab];
        [self reorderTabViews];
        [UIView beginAnimations:@"dragging tab view alpha" context:NULL];
        tabView.alpha = kTabBarDraggingTabAlpha;
        [UIView commitAnimations];
    } else if (gestureRecognizer.state == UIGestureRecognizerStateChanged) {
        draggingTabLocationCurrentX = currentPointX;
        
        // 调整被拖动的标签页的index
        NSInteger newIndex = [self indexForPosition:currentPointX];
        NSInteger tabsCount = [tabs count];
        if (newIndex < 0) {
            newIndex = 0;
        } else if(newIndex > tabsCount - 1) {
            newIndex = tabsCount - 1;
        }
        NSInteger oldIndex = [tabs indexOfObject:currentDraggingTab];
        if (oldIndex != newIndex) {
            [tabs removeObject:currentDraggingTab];
            [tabs insertObject:currentDraggingTab atIndex:newIndex];
#ifdef DEBUG
//            NSLog(@"move tab to index %d", newIndex);
#endif
            
            [tabViews removeObject:tabView];
            [tabViews insertObject:tabView atIndex:newIndex];
            [delegate tabBarViewTabDidMove:currentDraggingTab toIndex:newIndex];
        }
        [self layoutTabsWithAction:SWBTabBarActionDraggingTab animated:YES];
    } else if (gestureRecognizer.state == UIGestureRecognizerStateEnded) {
        
        [self layoutTabsWithAction:SWBTabBarActionDragTabEnded animated:YES];
        currentDraggingTab = nil;
        [self reorderTabViews];
    }
    
#ifdef DEBUG
//    NSLog(@"long press %@", gestureRecognizer.view);
//    //    NSLog(@"%f", firstPoint.x);
//    NSLog(@"%f", currentPointX);
#endif
    
}

-(void)setTitleForTab:(NSInteger)tag title:(NSString *)theTitle{
    [self tabViewByTag:tag].title = theTitle;
}

-(void)setLoadingForTab:(NSInteger)tag loading:(BOOL)loading {
    [self tabViewByTag:tag].loading = loading;
    
}

#pragma mark settings changed

-(void)settingsChanged {
    // TODO
    //    BOOL showEnd = [appSettingsManager showEndOfTheTitle];
    BOOL showEnd = NO;
    for (SWBTabView *tabView in tabViews) {
        tabView.titleLabel.lineBreakMode = showEnd? NSLineBreakByTruncatingMiddle:NSLineBreakByTruncatingTail;
    }
}

#pragma mark dealloc

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    for (SWBTabView *tabView in tabViews) {
        [self removeATabView:tabView];
    }
    [newTabButton removeTarget:self action:@selector(newTabButtonClicked) forControlEvents:UIControlEventTouchUpInside];
    
}

@end
