//
//  AQPageManager.h
//  AquaWeb
//
//  Created by clowwindy on 11-6-18.
//  Copyright 2011年 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SWBPage.h"

@interface SWBPageManager : NSObject {
    NSMutableArray *pages;
    NSMutableDictionary *tagToPageMapping;
}

@property (nonatomic,readonly) NSArray *pages;
@property (nonatomic,readonly) NSMutableDictionary *tagToPageMapping;
@property (nonatomic,readonly) NSInteger selectedIndex;

-(SWBPage *)addPageWithTag:(NSInteger)tag;
-(void)removePage:(NSInteger)tag;

-(void)initMappingAndTabsByPages;

-(SWBPage *)pageByTag:(NSInteger)tag;

-(void)save;
-(void)load;

@end
