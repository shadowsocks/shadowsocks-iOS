//
//  BridgeEditViewController.m
//  OnionBrowser
//
//  Created by Mike Tigas on 9/7/12.
//
//

#import "BridgeEditViewController.h"
#import "BridgeTableViewController.h"
#import "AppDelegate.h"

@interface BridgeEditViewController ()

@end

@implementation BridgeEditViewController
@synthesize bridge;

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (id)initWithBridge:(Bridge *)bridgeToEdit {
    self = [super initWithStyle:UITableViewStyleGrouped];
    if (self) {
        self.bridge = bridgeToEdit;
    }
    return self;
}


- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
    
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    return (IS_IPAD) || (interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 2;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section{
    if(section == 0)
        return @"Bridge IP Address\nShort instructions.\n\n1. Visit the following link to get bridge configuration lines that you can copy-and-paste here.\nhttps://bridges.torproject.org/\n\n2. Copy-and-paste everything in the \"bridge line\" after the word \"bridge\". (Should look something like \"128.30.30.25:9001\".)\n\nFull instructions w/screenshots can be found at\nhttp://onionbrowser.com/help/";
    else
        return nil;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return 1;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
    }
    
    if ((indexPath.section == 0)) {
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        
        CGRect textFrame;
        if (IS_IPAD) {
            textFrame = CGRectMake(50, 10,
                                   cell.contentView.frame.size.width-100, cell.contentView.frame.size.height-20);
        } else {
            textFrame = CGRectMake(20, 10,
                                   cell.contentView.frame.size.width-40, cell.contentView.frame.size.height-20);
        }
        UITextField *editField = [[UITextField alloc]
                                  initWithFrame:textFrame];
        editField.adjustsFontSizeToFitWidth = YES;
        editField.autoresizingMask = UIViewAutoresizingFlexibleWidth;
        
        /*
         editField.textColor = [UIColor blackColor];
         editField.backgroundColor = [UIColor whiteColor];
         */
        editField.textAlignment = UITextAlignmentLeft;
        editField.clearButtonMode = UITextFieldViewModeNever; // no clear 'x' button to the right
        [editField setEnabled: YES];
        editField.delegate = self;
        
        editField.autocorrectionType = UITextAutocorrectionTypeYes;
        editField.autocapitalizationType = UITextAutocapitalizationTypeWords;
        editField.text = bridge.conf;
        editField.returnKeyType = UIReturnKeyDone;
        editField.tag = 100;
        
        [cell addSubview:editField];
        
    } else {
        cell.selectionStyle = UITableViewCellSelectionStyleBlue;
        
        cell.textLabel.textAlignment = UITextAlignmentCenter;
        cell.textLabel.text = @"Done";
    }
    
    return cell;
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [self saveAndGoBack];
    return YES;
}

// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    return NO;
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 1)
        [self saveAndGoBack];
}

-(void)saveAndGoBack {
    NSUInteger titlePathInt[2] = {0,0};
    NSIndexPath* titlePath = [[NSIndexPath alloc] initWithIndexes:titlePathInt length:2];
    UITableViewCell *titleCell = [self.tableView cellForRowAtIndexPath:titlePath];
    UITextField *titleEditField = (UITextField*)[titleCell viewWithTag:100];
    bridge.conf = titleEditField.text;
    
    AppDelegate *appDelegate = [[UIApplication sharedApplication] delegate];
    NSError *error = nil;
    if (![appDelegate.managedObjectContext save:&error]) {
        NSLog(@"Error updating bridge: %@ %@", error, [error userInfo]);
    }
//    [appDelegate.tor hupTor];
    [self dismissModalViewControllerAnimated:YES];
}
@end
