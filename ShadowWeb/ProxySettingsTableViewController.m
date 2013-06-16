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


@interface ProxySettingsTableViewController () {
    SimpleTableViewSource *encryptionSource;
    SimpleTableViewSource *apnSource;
}

@end

@implementation ProxySettingsTableViewController

+(BOOL)settingsAreNotComplete {
    if ([[NSUserDefaults standardUserDefaults] stringForKey:kIPKey] == nil ||
         [[NSUserDefaults standardUserDefaults] stringForKey:kPortKey] == nil ||
          [[NSUserDefaults standardUserDefaults] stringForKey:kPasswordKey] == nil) {
             return YES;
         } else {
             return NO;
         }
}

+(BOOL)runProxy {
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

+(void)reloadConfig {
    if (![ProxySettingsTableViewController settingsAreNotComplete]) {
        NSString *v = [[NSUserDefaults standardUserDefaults] objectForKey:kEncryptionKey];
        if (!v) {
            v = @"aes-256-cfb";
        }
        set_config([[[NSUserDefaults standardUserDefaults] stringForKey:kIPKey] cStringUsingEncoding:NSUTF8StringEncoding], [[[NSUserDefaults standardUserDefaults] stringForKey:kPortKey] cStringUsingEncoding:NSUTF8StringEncoding], [[[NSUserDefaults standardUserDefaults] stringForKey:kPasswordKey] cStringUsingEncoding:NSUTF8StringEncoding], [v cStringUsingEncoding:NSUTF8StringEncoding]);
    }
}

-(void)saveConfigForKey:(NSString *)key value:(NSString *)value {
    [[NSUserDefaults standardUserDefaults] setObject:value forKey:key];
}

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    UIBarButtonItem *done = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(done)];
    self.navigationItem.rightBarButtonItem = done;
    UIBarButtonItem *cancel = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(cancel)];
    self.navigationItem.leftBarButtonItem = cancel;
    self.navigationItem.title = NSLocalizedString(@"Proxy Settings", nil);;
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;

    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
}

#pragma mark - navigation

-(void)cancel {
    [self dismissModalViewControllerAnimated:YES];
}

-(void)done {
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
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    return 5;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.row == 3) {
        UITableViewCell *cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"bb"];
        cell.textLabel.text = @"Encryption Method";
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        return cell;
    }
    if (indexPath.row == 4) {
        UITableViewCell *cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"bb"];
        cell.textLabel.text = @"Enable/Disable APN";
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
            cell.textLabel.text =  NSLocalizedString(@"IP", nil);
            textField.keyboardType = UIKeyboardTypeNumbersAndPunctuation;
            textField.secureTextEntry = NO;
            textField.text = [[NSUserDefaults standardUserDefaults] stringForKey:kIPKey];
            ipField = textField;
            break;
        case kPortRow:
            cell.textLabel.text =  NSLocalizedString(@"Port", nil);
            textField.keyboardType = UIKeyboardTypeNumberPad;
            textField.secureTextEntry = NO;
            textField.text = [[NSUserDefaults standardUserDefaults] stringForKey:kPortKey];
            portField = textField;
            break;
        case kPasswordRow:
            cell.textLabel.text =  NSLocalizedString(@"Password", nil);
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

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
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
        encryptionSource = [[SimpleTableViewSource alloc] initWithLabels:[NSArray arrayWithObjects:@"Table", @"AES-256-CFB", @"AES-192-CFB", @"AES-128-CFB", @"BF-CFB", nil]
                                                        values:[NSArray arrayWithObjects:@"table", @"aes-256-cfb", @"aes-192-cfb", @"aes-128-cfb", @"bf-cfb", nil]
                                                  initialValue:v selectionBlock:^(NSObject * value) {
            [[NSUserDefaults standardUserDefaults] setObject:value forKey:kEncryptionKey];
        }];
        UIViewController *controller = [[UIViewController alloc] init];
        UITableView *tableView1 = [[UITableView alloc] initWithFrame:controller.view.frame style:UITableViewStyleGrouped];
        tableView1.dataSource = encryptionSource;
        tableView1.delegate = encryptionSource;
        controller.view = tableView1;
        [self.navigationController pushViewController:controller animated:YES];
    } else if (indexPath.row == 4) {
        apnSource = [[SimpleTableViewSource alloc] initWithLabels:[NSArray arrayWithObjects:@"Enable Unicom", @"Disable Unicom", nil]
                                                        values:[NSArray arrayWithObjects:@"3gnet_enable", @"3gnet_disable", nil]
                                                  initialValue:nil selectionBlock:^(NSObject *value) {
                    SWBAppDelegate *appDelegate = (SWBAppDelegate *)[UIApplication sharedApplication].delegate;
                    NSString *v = (NSString *)value;
                    [appDelegate setPolipo:[v rangeOfString:@"enable"].length > 0];
                    // TODO: open after 1s, using a timer
                    [[UIApplication sharedApplication] openURL:
                            [NSURL URLWithString:[NSString stringWithFormat:@"http://localhost:8080/apn?id=%@", (NSString *)value]]];
        }];
        UIViewController *controller = [[UIViewController alloc] init];
        UITableView *tableView1 = [[UITableView alloc] initWithFrame:controller.view.frame style:UITableViewStyleGrouped];
        tableView1.dataSource = apnSource;
        tableView1.delegate = apnSource;
        controller.view = tableView1;
        [self.navigationController pushViewController:controller animated:YES];
    }
}

@end
