//
//  SWBNetworkActivityIndicatorManager.h
//  AquaWeb
//
//  Created by clowwindy on 11-7-3.
//  Copyright 2011年 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface SWBNetworkActivityIndicatorManager : NSObject {
    NSMutableSet *sources;
}

-(void)setSourceActivityStatusIsBusy:(id)source busy:(BOOL)busy;

@end
