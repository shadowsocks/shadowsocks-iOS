//
//  BookmarkEditViewController.h
//  OnionBrowser
//
//  Created by Mike Tigas on 9/7/12.
//
//

#import <UIKit/UIKit.h>
#import "Bookmark.h"

@interface BookmarkEditViewController : UITableViewController <UITextFieldDelegate> {
    Bookmark *bookmark;
}

-(id)initWithBookmark:(Bookmark*)bookmarkToEdit;
@property (nonatomic, retain) Bookmark *bookmark;


-(void)saveAndGoBack;
@end
