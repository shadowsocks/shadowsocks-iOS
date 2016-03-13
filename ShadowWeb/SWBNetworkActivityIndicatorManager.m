//
//  SWBNetworkActivityIndicatorManager.m
//  AquaWeb
//
//  Created by clowwindy on 11-7-3.
//  Copyright 2011年 __MyCompanyName__. All rights reserved.
//

#import "SWBNetworkActivityIndicatorManager.h"


@implementation SWBNetworkActivityIndicatorManager

- (id)init {
    self = [super init];
    if (self) {
        sources = [[NSMutableSet alloc] init];
    }
    return self;
}

-(void)setSourceActivityStatusIsBusy:(id)source busy:(BOOL)busy {
    if (busy&&![sources containsObject:source]) {
        [sources addObject:source];
    } else if([sources containsObject:source]){
        [sources removeObject:source];
    }
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:([sources count] > 0)];
}

@end
