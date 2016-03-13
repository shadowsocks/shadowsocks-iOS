//
//  SWBTabView.h
//  SWBuaWeb
//
//  Created by clowwindy on 11-6-10.
//  Copyright 2011年 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SWBSmallCloseButton.h"

@protocol SWBTabViewDelegate <NSObject>

@required

-(void) tabViewDidClickCloseButton:(id)sender;

@end

@interface SWBTabView : UIControl {
    SWBSmallCloseButton *closeButton;
    UILabel *titleLabel;
    UIActivityIndicatorView *indicatorView;
}

@property (nonatomic, assign) BOOL focused;
@property (nonatomic, weak) id<SWBTabViewDelegate> delegate;
@property (nonatomic, strong) IBOutlet NSString *title;
@property (nonatomic, assign) BOOL loading;
@property (weak, nonatomic, readonly) UILabel *titleLabel;

@end
