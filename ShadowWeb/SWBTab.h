//
//  SWBTab.h
//  SWBuaWeb
//
//  Created by clowwindy on 11-6-12.
//  Copyright 2011年 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface SWBTab : NSObject {
    NSInteger tag;
}

- (id)initWithTag:(NSInteger)aTag;

@property (nonatomic, strong) NSString *title;
@property (nonatomic, readonly) NSInteger tag;

@end
