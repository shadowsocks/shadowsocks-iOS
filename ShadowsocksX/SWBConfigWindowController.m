//
// Created by clowwindy on 14-2-26.
// Copyright (c) 2014 clowwindy. All rights reserved.
//

#import <openssl/evp.h>
#import <QuartzCore/QuartzCore.h>
#import "SWBConfigWindowController.h"
#import "ShadowsocksRunner.h"
#import "ProfileManager.h"
#import "encrypt.h"


@implementation SWBConfigWindowController {
    Configuration *configuration;
}


- (void)windowWillLoad {
    [super windowWillLoad];
}

- (void)addMethods {
    for (int i = 0; i < kShadowsocksMethods; i++) {
        const char* method_name = shadowsocks_encryption_names[i];
        NSString *methodName = [[NSString alloc] initWithBytes:method_name length:strlen(method_name) encoding:NSUTF8StringEncoding];
        [_methodBox addItemWithObjectValue:methodName];
    }
}

- (void)loadSettings {
    configuration = [ProfileManager configuration];
    [self.tableView reloadData];
    [self loadCurrentProfile];
}

- (void)saveSettings {
    [ProfileManager saveConfiguration:configuration];
//    if (_publicMatrix.selectedColumn == 0) {
//        [ShadowsocksRunner setUsingPublicServer:YES];
//    } else {
//        [ShadowsocksRunner setUsingPublicServer:NO];
//        [ShadowsocksRunner saveConfigForKey:kShadowsocksIPKey value:[_serverField stringValue]];
//        [ShadowsocksRunner saveConfigForKey:kShadowsocksPortKey value:[_portField stringValue]];
//        [ShadowsocksRunner saveConfigForKey:kShadowsocksPasswordKey value:[_passwordField stringValue]];
//        [ShadowsocksRunner saveConfigForKey:kShadowsocksEncryptionKey value:[_methodBox stringValue]];
//    }
//    if (self.delegate != nil) {
//        if ([self.delegate respondsToSelector:@selector(configurationDidChange)]) {
//            [self.delegate configurationDidChange];
//        }
//    }
}

- (BOOL)tableView:(NSTableView *)tableView shouldSelectRow:(NSInteger)row {
    if (self.tableView.selectedRow < 0) {
        // always allow no selection to selection
        return YES;
    }
    if (row >= 0 && row < configuration.profiles.count) {
        if ([self validateCurrentProfile]) {
            [self saveCurrentProfile];
        } else {
            return NO;
        }
    }
    // always allow selection to no selection
    return YES;
}

- (void)tableViewSelectionDidChange:(NSNotification *)notification {
    if (self.tableView.selectedRow >= 0) {
        [self loadCurrentProfile];
    }
}

- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
    Profile *profile = configuration.profiles[row];
    if ([profile.server isEqualToString:@""]) {
        return @"New Server";
    }
    return profile.server;
}

- (IBAction)sectionClick:(id)sender {
    NSInteger index = ((NSSegmentedControl *)sender).selectedSegment;
    if (index == 0) {
        [self add:sender];
    } else if (index == 1) {
        [self remove:sender];
    }
}

- (IBAction)add:(id)sender {
    if (configuration.profiles.count != 0 && ![self saveCurrentProfile]) {
        [self shakeWindow];
        return;
    }
    Profile *profile = [[Profile alloc] init];
    profile.server = @"";
    profile.serverPort = 8388;
    profile.method = @"aes-256-cfb";
    profile.password = @"";
    [((NSMutableArray *) configuration.profiles) addObject:profile];
    [self.tableView reloadData];
    [self.tableView selectRowIndexes:[NSIndexSet indexSetWithIndex:(configuration.profiles.count - 1)] byExtendingSelection:NO];
    [self updateSettingsBoxVisible:self];
    [self loadCurrentProfile];
}

- (IBAction)remove:(id)sender {
    NSInteger selection = self.tableView.selectedRow;
    if (selection >= 0 && selection < configuration.profiles.count) {
        [((NSMutableArray *) configuration.profiles) removeObjectAtIndex:selection];
        [self.tableView reloadData];
        [self updateSettingsBoxVisible:self];
        if (configuration.profiles.count > 0) {
            [self.tableView selectRowIndexes:[NSIndexSet indexSetWithIndex:(configuration.profiles.count - 1)] byExtendingSelection:NO];
        }
        [self loadCurrentProfile];
        if (configuration.current > selection) {
            // select the original profile
            configuration.current = configuration.current - 1;
        }
    }
}

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView {
    return configuration.profiles.count;
}

- (void)windowDidLoad {
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    [super windowDidLoad];
    [self addMethods];
    [self loadSettings];
    [self updateSettingsBoxVisible:self];
}

- (IBAction)updateSettingsBoxVisible:(id)sender {
    if (configuration.profiles.count == 0) {
        [_settingsBox setHidden:YES];
        [_placeholderLabel setHidden:NO];
    } else {
        [_settingsBox setHidden:NO];
        [_placeholderLabel setHidden:YES];
    }
}

- (void)loadCurrentProfile {
    if (configuration.profiles.count > 0) {
        if (self.tableView.selectedRow >= 0 && self.tableView.selectedRow < configuration.profiles.count) {
            Profile *profile = configuration.profiles[self.tableView.selectedRow];
            [_serverField setStringValue:profile.server];
            [_portField setStringValue:[NSString stringWithFormat:@"%ld", (long)profile.serverPort]];
            [_methodBox setStringValue:profile.method];
            [_passwordField setStringValue:profile.password];
            if (profile.remarks) {
                [_remarksField setStringValue:profile.remarks];
            } else {
                [_remarksField setStringValue:@""];
            }
        }
    }
}

- (BOOL)saveCurrentProfile {
    if (![self validateCurrentProfile]) {
        return NO;
    }
    if (self.tableView.selectedRow >= 0 && self.tableView.selectedRow < configuration.profiles.count) {
        Profile *profile = configuration.profiles[self.tableView.selectedRow];
        profile.server = [_serverField stringValue];
        profile.serverPort = [_portField integerValue];
        profile.method = [_methodBox stringValue];
        profile.password = [_passwordField stringValue];
        profile.remarks = [_remarksField stringValue];
    }

    return YES;
}

- (BOOL)validateCurrentProfile {
    if ([[_serverField stringValue] isEqualToString:@""]) {
        [_serverField becomeFirstResponder];
        return NO;
    }
    if ([_portField integerValue] == 0) {
        [_portField becomeFirstResponder];
        return NO;
    }
    if ([[_methodBox stringValue] isEqualToString:@""]) {
        [_methodBox becomeFirstResponder];
        return NO;
    }
    if ([[_passwordField stringValue] isEqualToString:@""]) {
        [_passwordField becomeFirstResponder];
        return NO;
    }
    return YES;
}

- (IBAction)OK:(id)sender {
    if ([self saveCurrentProfile]) {
        [self saveSettings];
        [ShadowsocksRunner reloadConfig];
        [self.delegate configurationDidChange];
        [self.window performClose:self];
    } else {
        [self shakeWindow];
    }
}

- (IBAction)cancel:(id)sender {
    [self.window performClose:self];
}

- (void)shakeWindow {
    static int numberOfShakes = 3;
    static float durationOfShake = 0.7f;
    static float vigourOfShake = 0.03f;

    CGRect frame=[self.window frame];
    CAKeyframeAnimation *shakeAnimation = [CAKeyframeAnimation animation];

    CGMutablePathRef shakePath = CGPathCreateMutable();
    CGPathMoveToPoint(shakePath, NULL, NSMinX(frame), NSMinY(frame));
    int index;
    for (index = 0; index < numberOfShakes; ++index)
    {
        CGPathAddLineToPoint(shakePath, NULL, NSMinX(frame) - frame.size.width * vigourOfShake, NSMinY(frame));
        CGPathAddLineToPoint(shakePath, NULL, NSMinX(frame) + frame.size.width * vigourOfShake, NSMinY(frame));
    }
    CGPathCloseSubpath(shakePath);
    shakeAnimation.path = shakePath;
    shakeAnimation.duration = durationOfShake;

    [self.window setAnimations:[NSDictionary dictionaryWithObject: shakeAnimation forKey:@"frameOrigin"]];
    [[self.window animator] setFrameOrigin:[self.window frame].origin];
}

@end