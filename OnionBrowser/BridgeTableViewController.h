//
//  BridgeTableViewController.h
//  OnionBrowser
//
//  Created by Mike Tigas on 9/7/12.
//
//

#import <UIKit/UIKit.h>

@interface BridgeTableViewController : UITableViewController <UIAlertViewDelegate> {
    NSMutableArray *bridgeArray;
    NSManagedObjectContext *managedObjectContext;
    UIBarButtonItem *addButton;
}

@property (nonatomic, retain) NSMutableArray *bridgeArray;
@property (nonatomic, retain) NSManagedObjectContext *managedObjectContext;
@property (nonatomic, retain) UIBarButtonItem *editButton;
@property (nonatomic, retain) UIBarButtonItem *addButton;
@property (nonatomic, retain) UIBarButtonItem *backButton;
@property (nonatomic, retain) UIBarButtonItem *editDoneButton;

- (void)reload;
- (void)addBridgeLine;
- (void)startEditing;
- (void)stopEditing;
- (void)goBack;
@end
