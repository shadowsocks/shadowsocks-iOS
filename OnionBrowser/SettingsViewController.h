//
//  SettingsViewController.h
//  OnionBrowser
//
//  Created by Mike Tigas on 5/2/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SettingsTableViewController.h"

@interface SettingsViewController : UIViewController

@property (nonatomic) IBOutlet UINavigationBar *navBar;
@property (nonatomic) IBOutlet SettingsTableViewController *tableVC;

- (IBAction)doneButton:(id)sender;
@end
