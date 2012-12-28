//
//  BookmarkListViewController.h
//  OnionBrowser
//
//  Created by Mike Tigas on 9/7/12.
//
//

#import <UIKit/UIKit.h>

@interface BookmarkTableViewController : UITableViewController {
    NSMutableArray *bookmarksArray;
    NSManagedObjectContext *managedObjectContext;
    UIBarButtonItem *addButton;
}

@property (nonatomic, retain) NSMutableArray *bookmarksArray;
@property (nonatomic, retain) NSManagedObjectContext *managedObjectContext;
@property (nonatomic, retain) UIBarButtonItem *editButton;
@property (nonatomic, retain) UIBarButtonItem *addButton;
@property (nonatomic, retain) UIBarButtonItem *backButton;
@property (nonatomic, retain) UIBarButtonItem *editDoneButton;

@property (readonly, nonatomic) NSArray *presetBookmarks;

- (void)saveBookmarkOrder;

- (void)reload;
- (void)addBookmark;
- (void)startEditing;
- (void)stopEditing;
- (void)goBack;
@end
