//
// Created by clowwindy on 14-2-26.
// Copyright (c) 2014 clowwindy. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface SWBConfigWindowController : NSWindowController

@property (nonatomic, strong) IBOutlet NSMatrix *publicMatrix;
@property (nonatomic, strong) IBOutlet NSTextField *serverField;
@property (nonatomic, strong) IBOutlet NSTextField *portField;
@property (nonatomic, strong) IBOutlet NSComboBox *methodBox;
@property (nonatomic, strong) IBOutlet NSSecureTextField *passwordField;
@property (nonatomic, strong) IBOutlet NSButton *okButton;
@property (nonatomic, strong) IBOutlet NSButton *cancelButton;
@property (nonatomic, strong) IBOutlet NSBox *settingsBox;

- (IBAction)OK:(id)sender;
- (IBAction)cancel:(id)sender;
- (IBAction)updateSettingsBoxVisible:(id)sender;

@end