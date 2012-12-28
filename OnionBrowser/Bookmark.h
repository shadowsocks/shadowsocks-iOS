//
//  Bookmark.h
//  OnionBrowser
//
//  Created by Mike Tigas on 9/9/12.
//
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@interface Bookmark : NSManagedObject

@property (nonatomic) int16_t order;
@property (nonatomic, retain) NSString * title;
@property (nonatomic, retain) NSString * url;

@end
