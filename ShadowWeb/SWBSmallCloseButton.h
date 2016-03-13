//
//  SWBSmallCloseButton.h
//  SWBuaWeb
//
//  Created by clowwindy on 11-6-10.
//  Copyright 2011年 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SWBSmallCloseButtonHighlightView.h"

@interface SWBSmallCloseButton : UIButton {
    SWBSmallCloseButtonHighlightView *highlightView;
}

@property (nonatomic, assign) CGFloat radius;

@end
