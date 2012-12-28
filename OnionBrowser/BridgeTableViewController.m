//
//  BridgeTableViewController.h
//  OnionBrowser
//
//  Created by Mike Tigas on 9/7/12.
//
//

#import "BridgeTableViewController.h"
#import "Bridge.h"
#import "AppDelegate.h"
#import "BridgeEditViewController.h"


@interface BridgeTableViewController ()

@end

@implementation BridgeTableViewController
@synthesize bridgeArray;
@synthesize managedObjectContext;
@synthesize addButton;
@synthesize editButton;
@synthesize backButton;
@synthesize editDoneButton;

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
    [self.tableView setAllowsSelectionDuringEditing:YES];
    
    self.title = @"Bridges";
    
    self.navigationItem.leftBarButtonItem = self.editButtonItem;
    
    addButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd
                                                              target:self action:@selector(addBridgeLine)];
    editButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemEdit
                                                               target:self action:@selector(startEditing)];
    editDoneButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone
                                                                   target:self action:@selector(stopEditing)];
    backButton = [[UIBarButtonItem alloc] initWithTitle:@"Back" style:UIBarButtonItemStyleDone target:self action:@selector(goBack)];
    self.navigationItem.leftBarButtonItem = editButton;
    self.navigationItem.rightBarButtonItem = backButton;
    [self reload];
}
- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [self reload];
}
-(void)reload {
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"Bridge" inManagedObjectContext:managedObjectContext];
    [request setEntity:entity];

    NSError *error = nil;
    NSMutableArray *mutableFetchResults = [[managedObjectContext executeFetchRequest:request error:&error] mutableCopy];
    if (mutableFetchResults == nil) {
        // Handle the error.
    }
    [self setBridgeArray:mutableFetchResults];
    [self.tableView reloadData];
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    self.bridgeArray = nil;
    self.addButton = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    return (IS_IPAD) || (interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [bridgeArray count];
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    return YES;
}
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = @"Cell";
    
    // Dequeue or create a new cell.
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier];
        [cell setEditingAccessoryType:UITableViewCellAccessoryDisclosureIndicator];
    }
    
    Bridge *bridge = (Bridge *)[bridgeArray objectAtIndex:indexPath.row];
    cell.textLabel.text = bridge.conf;
    return cell;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        
        // Delete the managed object at the given index path.
        NSManagedObject *bridgeToDelete = [bridgeArray objectAtIndex:indexPath.row];
        [managedObjectContext deleteObject:bridgeToDelete];
        
        // Update the array and table view.
        [bridgeArray removeObjectAtIndex:indexPath.row];
        [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:YES];
        // Commit the change.
        NSError *error = nil;
        if (![managedObjectContext save:&error]) {
            // Handle the error.
        }
    }
}


#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    // Open an editing pane
    Bridge *bridge = (Bridge *)[bridgeArray objectAtIndex:indexPath.row];
    BridgeEditViewController *editController = [[BridgeEditViewController alloc] initWithBridge:bridge];
    [self presentModalViewController:editController animated:YES];
}

- (void)addBridgeLine {
    Bridge *bridge = (Bridge *)[NSEntityDescription insertNewObjectForEntityForName:@"Bridge" inManagedObjectContext:managedObjectContext];
    
    [bridge setConf:@"Tap Here To Edit"];
    
    NSError *error = nil;
    if (![managedObjectContext save:&error]) {
        NSLog(@"Error adding bridge: %@", error);
    }
    [bridgeArray addObject:bridge];
    
    [self reload];
}

- (void)setEditing:(BOOL)editing animated:(BOOL)animated {
    if (editing) {
        self.navigationItem.leftBarButtonItem = editDoneButton;
        self.navigationItem.rightBarButtonItem = addButton;
    } else {
        self.navigationItem.leftBarButtonItem = editButton;
        self.navigationItem.rightBarButtonItem = backButton;
    }
    [super setEditing:editing animated:animated];
}

- (void)startEditing {
    [self setEditing:YES];
}
- (void)stopEditing {
    [self setEditing:NO];
}
- (void)goBack {
    // Now that we're exiting the list, prune out things that haven't been
    // edited or are just empty string.
    NSUInteger i = 0;
    for (Bridge *bridge in bridgeArray) {
        if ([bridge.conf isEqualToString:@"Tap Here To Edit"]||[bridge.conf isEqualToString:@""]) {
            [managedObjectContext deleteObject:bridge];
            [bridgeArray removeObjectAtIndex:i];
        }
        i++;
    }
    [self.tableView reloadData];
    [managedObjectContext save:NULL];
    // End pruning.
    
    AppDelegate *appDelegate = [[UIApplication sharedApplication] delegate];
//    if (![appDelegate.tor didFirstConnect]) {
//        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Please Restart App"
//                                                        message:@"Onion Browser will now close. Please start the app again to retry the Tor connection with the newly-configured bridges.\n\n(If you restart and the app stays stuck at \"Connecting...\", please come back and double-check your bridge configuration or remove your bridges.)"
//                                                       delegate:self
//                                              cancelButtonTitle:@"OK"
//                                              otherButtonTitles:nil];
//        [alert show];
//    } else {
        if ([bridgeArray count] > 0) {
            NSString *pluralize = @" is";
            if ([bridgeArray count] > 1) {
                pluralize = @"s are";
            }
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Bridges"
                                                            message:[NSString stringWithFormat:@"%d bridge%@ configured.You may need to quit the app and restart it to change the connection method.\n\n(If you restart and the app stays stuck at \"Connecting...\", please come back and double-check your bridge configuration or remove your bridges.)", [bridgeArray count], pluralize]
                                                           delegate:self
                                                  cancelButtonTitle:@"Continue anyway"
                                                  otherButtonTitles:@"Quit app", nil];
            [alert show];
        } else {
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Bridges Disabled"
                                                            message:@"No bridges are configured, so bridge connection mode is disabled. If you previously had bridges, you may need to quit the app and restart it to change the connection method.\n\n(If you restart and the app stays stuck at \"Connecting...\", please come back and double-check your bridge configuration or remove your bridges.)"
                                                           delegate:self
                                                  cancelButtonTitle:@"Continue anyway"
                                                  otherButtonTitles:@"Quit app", nil];
            [alert show];
        }
//    }
}

- (void) alertView:(UIAlertView *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
    if ([actionSheet.title isEqualToString:@"Please Restart App"]) {
        exit(0);
    } else {
        // One of the "Bridges Enabled" or "Bridges Disabled" prompts
        if (buttonIndex == 0) {
            [self dismissModalViewControllerAnimated:YES];
        } else {
            exit(0);
        }
    }
}
@end
