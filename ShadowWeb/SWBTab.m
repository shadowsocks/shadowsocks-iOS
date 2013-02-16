//
//  SWBTab.m
//  SWBuaWeb
//
//  Created by clowwindy on 11-6-12.
//  Copyright 2011年 __MyCompanyName__. All rights reserved.
//

#import "SWBTab.h"


@implementation SWBTab

@synthesize title, tag;

- (id)initWithTag:(NSInteger)aTag {
    self = [super init];
    if (self) {
        self->tag = aTag;
    }
    return self;
}

@end
