//
//  ProxySettingsTableViewController.m
//  shadowsocks-iOS
//
//  Created by clowwindy on 12-12-31.
//  Copyright (c) 2012年 clowwindy. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ProxySettingsTableViewController.h"
#import "SimpleTableViewSource.h"
#import "local.h"
#import "SWBAppDelegate.h"

// rows

#define kIPRow 0
#define kPortRow 1
#define kPasswordRow 2

// config keys

#define kIPKey @"proxy ip"
#define kPortKey @"proxy port"
#define kPasswordKey @"proxy password"
#define kEncryptionKey @"proxy encryption"
#define kProxyModeKey @"proxy mode"
#define kUsePublicServer @"public server"


@interface ProxySettingsTableViewController () {
    SimpleTableViewSource *encryptionSource;
    SimpleTableViewSource *apnSource;
    SimpleTableViewSource *modeSource;
}

@end

@implementation ProxySettingsTableViewController

+ (BOOL)settingsAreNotComplete {
    if ((![ProxySettingsTableViewController isUsingPublicServer]) && ([[NSUserDefaults standardUserDefaults] stringForKey:kIPKey] == nil ||
            [[NSUserDefaults standardUserDefaults] stringForKey:kPortKey] == nil ||
            [[NSUserDefaults standardUserDefaults] stringForKey:kPasswordKey] == nil)) {
        return YES;
    } else {
        return NO;
    }
}

+ (BOOL)runProxy {
    if (![ProxySettingsTableViewController settingsAreNotComplete]) {
        local_main();
        return YES;
    } else {
#ifdef DEBUG
        NSLog(@"warning: settings are not complete");
#endif
        return NO;
    }
}

+ (void)reloadConfig {
    if (![ProxySettingsTableViewController settingsAreNotComplete]) {
        if ([ProxySettingsTableViewController isUsingPublicServer]) {
            set_config("106.186.124.182", "8910", "Shadowsocks", "aes-128-cfb");
            memcpy(shadowsocks_key, "\x45\xd1\xd9\x9e\xbd\xf5\x8c\x85\x34\x55\xdd\x65\x46\xcd\x06\xd3", 16);
        } else {
            NSString *v = [[NSUserDefaults standardUserDefaults] objectForKey:kEncryptionKey];
            if (!v) {
                v = @"aes-256-cfb";
            }
            set_config([[[NSUserDefaults standardUserDefaults] stringForKey:kIPKey] cStringUsingEncoding:NSUTF8StringEncoding], [[[NSUserDefaults standardUserDefaults] stringForKey:kPortKey] cStringUsingEncoding:NSUTF8StringEncoding], [[[NSUserDefaults standardUserDefaults] stringForKey:kPasswordKey] cStringUsingEncoding:NSUTF8StringEncoding], [v cStringUsingEncoding:NSUTF8StringEncoding]);
        }
    }
}

- (void)saveConfigForKey:(NSString *)key value:(NSString *)value {
    [[NSUserDefaults standardUserDefaults] setObject:value forKey:key];
}

+ (BOOL)isUsingPublicServer {
    NSNumber *usePublicServer = [[NSUserDefaults standardUserDefaults] objectForKey:kUsePublicServer];
    if (usePublicServer != nil) {
        return [usePublicServer boolValue];
    } else {
        return YES;
    }
}

- (void)changePublicServer:(UISegmentedControl *)segmentedControl {
    BOOL result = NO;
    if (segmentedControl.selectedSegmentIndex == 0) {
        result = YES;
    }
    [[NSUserDefaults standardUserDefaults] setBool:result forKey:kUsePublicServer];
    if ((self.tableView.numberOfSections == 1) && !result) {
        [self.tableView insertSections:[NSIndexSet indexSetWithIndex:1] withRowAnimation:UITableViewRowAnimationFade];
    } else if ((self.tableView.numberOfSections == 2) && result) {
        [self.tableView deleteSections:[NSIndexSet indexSetWithIndex:1] withRowAnimation:UITableViewRowAnimationFade];
    }
}

- (id)initWithStyle:(UITableViewStyle)style {
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];

    UIBarButtonItem *done = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(done)];
    self.navigationItem.rightBarButtonItem = done;
    UIBarButtonItem *cancel = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(cancel)];
    self.navigationItem.leftBarButtonItem = cancel;
    self.navigationItem.title = _L(Proxy
    Settings);

    self.contentSizeForViewInPopover = CGSizeMake(320, 400);
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;

    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
}

#pragma mark - navigation

- (void)cancel {
    [self dismissModalViewControllerAnimated:YES];
    if (self->_myPopoverController) {
        [_myPopoverController dismissPopoverAnimated:YES];
    }
}

- (void)done {
    if (ipField.text == nil) {
        ipField.text = @"";
    }
    if (portField.text == nil) {
        portField.text = @"";
    }
    if (passwordField.text == nil) {
        passwordField.text = @"";
    }
    [self saveConfigForKey:kIPKey value:ipField.text];
    [self saveConfigForKey:kPortKey value:portField.text];
    [self saveConfigForKey:kPasswordKey value:passwordField.text];

    [ProxySettingsTableViewController reloadConfig];

    [self dismissModalViewControllerAnimated:YES];
    if (self->_myPopoverController) {
        [_myPopoverController dismissPopoverAnimated:YES];
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    // Return the number of sections.
    if ([ProxySettingsTableViewController isUsingPublicServer]) {
        return 1;
    }
    return 2;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    if (section == 0) {
        return _L(Server);
    } else {
        return nil;
    }
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    // Return the number of rows in the section.
    if (section == 0) {
        return 1;
    }
    return 5;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    if(indexPath.section == 0) {
        UITableViewCell *cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"c"];
        UISegmentedControl *segmentedControl = [[UISegmentedControl alloc] initWithItems:@[_L(Public), _L(Custom)]];
        [cell.contentView addSubview:segmentedControl];
        segmentedControl.center = CGPointMake(320 * 0.5f, cell.bounds.size.height * 0.5f);
        if ([ProxySettingsTableViewController isUsingPublicServer]) {
            segmentedControl.selectedSegmentIndex = 0;
        } else {
            segmentedControl.selectedSegmentIndex = 1;
        }
        [segmentedControl addTarget:self action:@selector(changePublicServer:) forControlEvents:UIControlEventValueChanged];
        return cell;
    } else if (indexPath.section == 1) {
        if (indexPath.row == 3) {
            UITableViewCell *cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"bb"];
            cell.textLabel.text = _L(Method);
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
            return cell;
        }
        if (indexPath.row == 4) {
            UITableViewCell *cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"bb"];
            cell.textLabel.text = _L(Proxy
            Mode);
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
            return cell;
        }
        if (indexPath.row == 5) {
            UITableViewCell *cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"bb"];
            cell.textLabel.text = _L(Enable / Disable
            APN);
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
            return cell;
        }
        UITableViewCell *cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"aaaaa"];
        UITextField *textField = [[UITextField alloc] initWithFrame:CGRectMake(110, 10, 185, 30)];
        textField.adjustsFontSizeToFitWidth = YES;
        textField.autocorrectionType = UITextAutocorrectionTypeNo;
        textField.autocapitalizationType = UITextAutocapitalizationTypeNone;
        textField.returnKeyType = UIReturnKeyDone;
        switch (indexPath.row) {
            case kIPRow:
                cell.textLabel.text = _L(IP);
                textField.keyboardType = UIKeyboardTypeNumbersAndPunctuation;
                textField.secureTextEntry = NO;
                textField.text = [[NSUserDefaults standardUserDefaults] stringForKey:kIPKey];
                ipField = textField;
                break;
            case kPortRow:
                cell.textLabel.text = _L(Port);
                textField.keyboardType = UIKeyboardTypeNumberPad;
                textField.secureTextEntry = NO;
                textField.text = [[NSUserDefaults standardUserDefaults] stringForKey:kPortKey];
                portField = textField;
                break;
            case kPasswordRow:
                cell.textLabel.text = _L(Password);
                textField.keyboardType = UIKeyboardTypeDefault;
                textField.secureTextEntry = YES;
                textField.text = [[NSUserDefaults standardUserDefaults] stringForKey:kPasswordKey];
                passwordField = textField;
                break;
            default:
                break;
        }
        [cell addSubview:textField];
        cell.selectionStyle = UITableViewCellSelectionStyleNone;

        return cell;
    }
    return nil;
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    // Navigation logic may go here. Create and push another view controller.
    /*
     <#DetailViewController#> *detailViewController = [[<#DetailViewController#> alloc] initWithNibName:@"<#Nib name#>" bundle:nil];
     // ...
     // Pass the selected object to the new view controller.
     [self.navigationController pushViewController:detailViewController animated:YES];
     */
    if (indexPath.row == 3) {
        NSString *v = [[NSUserDefaults standardUserDefaults] objectForKey:kEncryptionKey];
        if (!v) {
            v = @"aes-256-cfb";
        }
        encryptionSource = [[SimpleTableViewSource alloc] initWithLabels:[NSArray arrayWithObjects:@"table",
                                                                                                   @"aes-256-cfb",
                                                                                                   @"aes-192-cfb",
                                                                                                   @"aes-128-cfb",
                                                                                                   @"bf-cfb",
                                                                                                   @"camellia-128-cfb",
                                                                                                   @"camellia-192-cfb",
                                                                                                   @"camellia-256-cfb",
                                                                                                   @"cast5-cfb",
                                                                                                   @"des-cfb",
                                                                                                   @"idea-cfb",
                                                                                                   @"rc2-cfb",
                                                                                                   @"rc4",
                                                                                                   @"seed-cfb",
                                                                                                   nil]
                                                                  values:[NSArray arrayWithObjects:@"table",
                                                                                                   @"aes-256-cfb",
                                                                                                   @"aes-192-cfb",
                                                                                                   @"aes-128-cfb",
                                                                                                   @"bf-cfb",
                                                                                                   @"camellia-128-cfb",
                                                                                                   @"camellia-192-cfb",
                                                                                                   @"camellia-256-cfb",
                                                                                                   @"cast5-cfb",
                                                                                                   @"des-cfb",
                                                                                                   @"idea-cfb",
                                                                                                   @"rc2-cfb",
                                                                                                   @"rc4",
                                                                                                   @"seed-cfb",
                                                                                                   nil]
                                                            initialValue:v selectionBlock:^(NSObject *value) {
                    [[NSUserDefaults standardUserDefaults] setObject:value forKey:kEncryptionKey];
                }];
        UIViewController *controller = [[UIViewController alloc] init];
        controller.contentSizeForViewInPopover = self.contentSizeForViewInPopover;
        controller.navigationItem.title = _L(Method);
        UITableView *tableView1 = [[UITableView alloc] initWithFrame:controller.view.frame style:UITableViewStyleGrouped];
        tableView1.dataSource = encryptionSource;
        tableView1.delegate = encryptionSource;
        controller.view = tableView1;
        [self.navigationController pushViewController:controller animated:YES];
    } else if (indexPath.row == 4) {
        NSString *v = [[NSUserDefaults standardUserDefaults] objectForKey:kProxyModeKey];
        if (!v) {
            v = @"pac";
        }
        modeSource = [[SimpleTableViewSource alloc] initWithLabels:[NSArray arrayWithObjects:_L(PAC), _L(Global), _L(Off), nil]
                                                            values:[NSArray arrayWithObjects:@"pac", @"global", @"off", nil]
                                                      initialValue:v selectionBlock:^(NSObject *value) {
                    [[NSUserDefaults standardUserDefaults] setObject:value forKey:kProxyModeKey];
                    SWBAppDelegate *appDelegate = (SWBAppDelegate *) [UIApplication sharedApplication].delegate;
                    [appDelegate updateProxyMode];
                }];
        UIViewController *controller = [[UIViewController alloc] init];
        controller.contentSizeForViewInPopover = CGSizeMake(320, 480);
        controller.navigationItem.title = _L(Proxy
        Mode);
        UITableView *tableView1 = [[UITableView alloc] initWithFrame:controller.view.frame style:UITableViewStyleGrouped];
        tableView1.dataSource = modeSource;
        tableView1.delegate = modeSource;
        controller.view = tableView1;
        [self.navigationController pushViewController:controller animated:YES];
    } else if (indexPath.row == 5) {
        apnSource = [[SimpleTableViewSource alloc] initWithLabels:[NSArray arrayWithObjects:_L(Enable
        Unicom), _L(Disable
        Unicom), nil]
                                                           values:[NSArray arrayWithObjects:@"3gnet_enable", @"3gnet_disable", nil]
                                                     initialValue:nil selectionBlock:^(NSObject *value) {
                    SWBAppDelegate *appDelegate = (SWBAppDelegate *) [UIApplication sharedApplication].delegate;
                    NSString *v = (NSString *) value;
                    [appDelegate setPolipo:[v rangeOfString:@"enable"].length > 0];
                    // TODO: open after 1s, using a timer
                    [[UIApplication sharedApplication] openURL:
                            [NSURL URLWithString:[NSString stringWithFormat:@"http://localhost:8080/apn?id=%@", (NSString *) value]]];
                }];
        UIViewController *controller = [[UIViewController alloc] init];
        controller.contentSizeForViewInPopover = CGSizeMake(320, 480);
        UITableView *tableView1 = [[UITableView alloc] initWithFrame:controller.view.frame style:UITableViewStyleGrouped];
        tableView1.dataSource = apnSource;
        tableView1.delegate = apnSource;
        controller.view = tableView1;
        [self.navigationController pushViewController:controller animated:YES];
    }
}

@end
