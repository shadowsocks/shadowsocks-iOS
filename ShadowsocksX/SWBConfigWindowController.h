//
// Created by clowwindy on 14-2-26.
// Copyright (c) 2014 clowwindy. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@protocol SWBConfigWindowControllerDelegate <NSObject>

@optional
- (void)configurationDidChange;

@end

@interface SWBConfigWindowController : NSWindowController <NSTableViewDataSource, NSTableViewDelegate>

@property (nonatomic, strong) IBOutlet NSTableView *tableView;
@property (nonatomic, strong) IBOutlet NSTextField *serverField;
@property (nonatomic, strong) IBOutlet NSTextField *portField;
@property (nonatomic, strong) IBOutlet NSComboBox *methodBox;
@property (nonatomic, strong) IBOutlet NSSecureTextField *passwordField;
@property (nonatomic, strong) IBOutlet NSTextField *remarksField;
@property (nonatomic, strong) IBOutlet NSButton *okButton;
@property (nonatomic, strong) IBOutlet NSButton *cancelButton;
@property (nonatomic, strong) IBOutlet NSBox *settingsBox;
@property (nonatomic, strong) IBOutlet NSTextField *placeholderLabel;
@property (nonatomic, weak) id<SWBConfigWindowControllerDelegate> delegate;

- (IBAction)OK:(id)sender;
- (IBAction)cancel:(id)sender;

- (IBAction)sectionClick:(id)sender;

@end