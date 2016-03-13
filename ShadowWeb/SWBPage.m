//
//  AQPage.m
//  AquaWeb
//
//  Created by clowwindy on 11-6-18.
//  Copyright (c) 2011年 __MyCompanyName__. All rights reserved.
//

#import "SWBPage.h"


@implementation SWBPage
@synthesize title;
@synthesize url;
@synthesize selected;
@synthesize tag;

- (BOOL)isSelected {
    return [self.selected boolValue];
}
@end
