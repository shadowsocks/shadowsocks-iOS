//
//  AQPageManager.m
//  AquaWeb
//
//  Created by clowwindy on 11-6-18.
//  Copyright 2011年 __MyCompanyName__. All rights reserved.
//

#import "SWBPageManager.h"
#import "JSONKit.h"
//#import "AquaWebAppDelegate.h"

#define pageSavingDirectory [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) objectAtIndex:0] 

#define pageFilename [pageSavingDirectory stringByAppendingPathComponent:@"pages.json"]

@implementation SWBPageManager

@synthesize pages, tagToPageMapping;

- (id)init {
    self = [super init];
    if (self) {
        pages = [[NSMutableArray alloc] init];
        tagToPageMapping = [[NSMutableDictionary alloc] init];
            }
    return self;
}

-(SWBPage *)addPageWithTag:(NSInteger)tag {
//    AQPage *page = [NSEntityDescription insertNewObjectForEntityForName:kAQPageClass inManagedObjectContext:objContext];
    SWBPage *page = [[SWBPage alloc] init];
    
    page.tag = tag;
    [pages addObject:page];
    [tagToPageMapping setValue:page forKey:[NSString stringWithFormat:@"%d", tag]];
    return page;
}

-(void)removePage:(NSInteger)tag {
    SWBPage *page = [self pageByTag:tag];
//    [objContext deleteObject:page];
    [pages removeObject:page];
    [tagToPageMapping removeObjectForKey:[NSString stringWithFormat:@"%d", tag]];
}


-(void)initMappingAndTabsByPages {
    [tagToPageMapping removeAllObjects];
    NSUInteger count = [pages count];
    for (int i = 0; i < count; i++) {
        [tagToPageMapping setValue:[pages objectAtIndex:i] forKey:[NSString stringWithFormat:@"%d", i]];
    }
}

-(SWBPage *)pageByTag:(NSInteger)tag {
    return [tagToPageMapping valueForKey:[NSString stringWithFormat:@"%d", tag]];    
}

-(void)save {
//    NSError *error;
//    [objContext save:&error];
    NSMutableArray *data = [[NSMutableArray alloc] init];
    for (SWBPage *page in pages) {
        NSMutableDictionary *dict = [[NSMutableDictionary alloc] initWithCapacity:4];
        [dict setObject:page.title forKey:@"title"];
        [dict setObject:page.url forKey:@"url"];
        [dict setObject:page.selected forKey:@"selected"];
        [data addObject:dict];
    }
    NSString *content = [data JSONString];
    NSError *error = nil;
    [content writeToFile:pageFilename atomically:YES encoding:NSUTF8StringEncoding error:&error];
    if (error != NULL) {
        NSLog(@"%@", error);
    }
}

-(void)load {
    
    NSMutableArray *oldpages = [[NSMutableArray alloc] init];
    
    NSError *error = nil;
    NSString *content = [NSString stringWithContentsOfFile:pageFilename encoding:NSUTF8StringEncoding error:&error];
    if (error == NULL) {
        NSArray *data = [content objectFromJSONString];
        for (NSDictionary *dict in data) {
            SWBPage *page = [[SWBPage alloc] init];
            page.title = [dict objectForKey:@"title"];
            page.url = [dict objectForKey:@"url"];
            page.selected = [dict objectForKey:@"selected"];
            [oldpages addObject:page];
        }
    } else {
        NSLog(@"%@", error);
    }
    
    if (oldpages != nil) {
        for (SWBPage *page in oldpages) {
            [pages addObject:page];
        }
    }
    
}

-(NSInteger)selectedIndex {
    for (NSInteger i = 0; i < [pages count]; i++) {
        if ([((SWBPage *)[pages objectAtIndex:i]).selected boolValue]) {
            return i;
        }
    }
    return 0;
}

@end
