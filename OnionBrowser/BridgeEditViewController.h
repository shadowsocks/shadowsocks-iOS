//
//  BridgeEditViewController.h
//  OnionBrowser
//
//  Created by Mike Tigas on 9/7/12.
//
//

#import <UIKit/UIKit.h>
#import "Bridge.h"

@interface BridgeEditViewController : UITableViewController <UITextFieldDelegate> {
    Bridge *bridge;
}

-(id)initWithBridge:(Bridge*)bridgeToEdit;
@property (nonatomic, retain) Bridge *bridge;


-(void)saveAndGoBack;
@end
