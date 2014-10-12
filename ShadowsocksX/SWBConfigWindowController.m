//
// Created by clowwindy on 14-2-26.
// Copyright (c) 2014 clowwindy. All rights reserved.
//

#import <openssl/evp.h>
#import "SWBConfigWindowController.h"
#import "ShadowsocksRunner.h"
#import "encrypt.h"


@implementation SWBConfigWindowController {

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
    if ([ShadowsocksRunner isUsingPublicServer]) {
        [_publicMatrix selectCellAtRow:0 column:0];
    } else {
        [_publicMatrix selectCellAtRow:0 column:1];
    }
    if ([ShadowsocksRunner configForKey:kShadowsocksIPKey]) {
        [_serverField setStringValue:[ShadowsocksRunner configForKey:kShadowsocksIPKey]];
    }
    if ([ShadowsocksRunner configForKey:kShadowsocksPortKey]) {
        [_portField setStringValue:[ShadowsocksRunner configForKey:kShadowsocksPortKey]];
    } else {
        [_portField setStringValue:@"8388"];
    }
    if ([ShadowsocksRunner configForKey:kShadowsocksPasswordKey]) {
        [_passwordField setStringValue:[ShadowsocksRunner configForKey:kShadowsocksPasswordKey]];
    }
    if ([ShadowsocksRunner configForKey:kShadowsocksEncryptionKey]) {
        [_methodBox setStringValue:[ShadowsocksRunner configForKey:kShadowsocksEncryptionKey]];
    } else {
        [_methodBox setStringValue:@"aes-256-cfb"];
    }
}

- (void)saveSettings {
    if (_publicMatrix.selectedColumn == 0) {
        [ShadowsocksRunner setUsingPublicServer:YES];
    } else {
        [ShadowsocksRunner setUsingPublicServer:NO];
        [ShadowsocksRunner saveConfigForKey:kShadowsocksIPKey value:[_serverField stringValue]];
        [ShadowsocksRunner saveConfigForKey:kShadowsocksPortKey value:[_portField stringValue]];
        [ShadowsocksRunner saveConfigForKey:kShadowsocksPasswordKey value:[_passwordField stringValue]];
        [ShadowsocksRunner saveConfigForKey:kShadowsocksEncryptionKey value:[_methodBox stringValue]];
    }
    if (self.delegate != nil) {
        if ([self.delegate respondsToSelector:@selector(configurationDidChange)]) {
            [self.delegate configurationDidChange];
        }
    }
}

- (void)windowDidLoad {
    [super windowDidLoad];
    [self addMethods];
    [self loadSettings];
    [self updateSettingsBoxVisible:self];
}

- (IBAction)updateSettingsBoxVisible:(id)sender {
    if (_publicMatrix.selectedColumn == 0) {
        [_settingsBox setHidden:YES];
    } else {
        [_settingsBox setHidden:NO];
    }
}

- (BOOL)validateSettings {
    if (_publicMatrix.selectedColumn == 0) {
        return YES;
    }
    if ([[_serverField stringValue] isEqualToString:@""]) {
        return NO;
    }
    if ([_portField integerValue] == 0) {
        return NO;
    }
    if ([[_methodBox stringValue] isEqualToString:@""]) {
        return NO;
    }
    if ([[_passwordField stringValue] isEqualToString:@""]) {
        return NO;
    }
    return YES;
}

- (IBAction)OK:(id)sender {
    if ([self validateSettings]) {
        [self saveSettings];
        [ShadowsocksRunner reloadConfig];
        [self.window performClose:self];
    } else {
        NSAlert *alert = [[NSAlert alloc] init];
        [alert addButtonWithTitle:_L(OK)];
        [alert setMessageText:_L(Please fill in the blanks.)];
        [alert setAlertStyle:NSCriticalAlertStyle];
        [alert beginSheetModalForWindow:self.window modalDelegate:self didEndSelector:nil contextInfo:nil];
    }
}

- (IBAction)cancel:(id)sender {
    [self.window performClose:self];
}


@end