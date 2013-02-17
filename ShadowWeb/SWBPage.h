//
//  AQPage.h
//  AquaWeb
//
//  Created by clowwindy on 11-6-18.
//  Copyright (c) 2011年 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface SWBPage : NSObject {

}
@property (nonatomic, strong) NSString * title;
@property (nonatomic, strong) NSString * url;
@property (nonatomic, strong) NSNumber * selected;
@property (nonatomic, assign) NSInteger tag; /* not saved into JSON */


@end
