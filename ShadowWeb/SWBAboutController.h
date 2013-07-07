//
// Created by clowwindy on 7/7/13.
// Copyright (c) 2013 clowwindy. All rights reserved.
//
// To change the template use AppCode | Preferences | File Templates.
//


#import <Foundation/Foundation.h>
#import <MessageUI/MessageUI.h>
#import <MessageUI/MFMailComposeViewController.h>



@interface SWBAboutController : UITableViewController <MFMailComposeViewControllerDelegate> {

}

@property (nonatomic, weak) UIPopoverController *myPopoverController;

@end