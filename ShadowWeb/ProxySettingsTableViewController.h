//
//  ProxySettingsTableViewController.h
//  shadowsocks-iOS
//
//  Created by clowwindy on 12-12-31.
//  Copyright (c) 2012年 clowwindy. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ProxySettingsTableViewController : UITableViewController {
    UITextField *ipField;
    UITextField *portField;
    UITextField *passwordField;
}

@property (nonatomic, weak) UIPopoverController *myPopoverController;
@end
