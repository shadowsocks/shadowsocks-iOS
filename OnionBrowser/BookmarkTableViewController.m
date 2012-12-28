//
//  BookmarkListViewController.m
//  OnionBrowser
//
//  Created by Mike Tigas on 9/7/12.
//
//

#import "BookmarkTableViewController.h"
#import "Bookmark.h"
#import "BookmarkEditViewController.h"
#import "AppDelegate.h"

@interface BookmarkTableViewController ()

@end

@implementation BookmarkTableViewController
@synthesize bookmarksArray;
@synthesize managedObjectContext;
@synthesize addButton;
@synthesize editButton;
@synthesize backButton;
@synthesize editDoneButton;
@synthesize presetBookmarks = _presetBookmarks;

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (NSArray *)presetBookmarks {
    if (_presetBookmarks == nil) {
        _presetBookmarks = [NSArray arrayWithObjects:
                            [NSArray arrayWithObjects:@"Main Site", @"http://onionbrowser.com/", nil],
                            [NSArray arrayWithObjects:@"Source Code Site", @"https://github.com/mtigas/iOS-OnionBrowser/", nil],
                            [NSArray arrayWithObjects:@"Version History", @"https://raw.github.com/mtigas/iOS-OnionBrowser/master/CHANGES.txt", nil],
                            [NSArray arrayWithObjects:@"Mike Tigas, App Developer", @"http://mike.tig.as/", nil],
                            [NSArray arrayWithObjects:@"Tor Bridges", @"https://bridges.torproject.org/", nil],
                             nil];
    }
    return _presetBookmarks;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self.tableView setAllowsSelectionDuringEditing:YES];

    self.title = @"Bookmarks";
    
    self.navigationItem.leftBarButtonItem = self.editButtonItem;
    
    addButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd
                                                              target:self action:@selector(addBookmark)];
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
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"Bookmark" inManagedObjectContext:managedObjectContext];
    [request setEntity:entity];
    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"order" ascending:YES];
    NSArray *sortDescriptors = [[NSArray alloc] initWithObjects:sortDescriptor, nil];
    [request setSortDescriptors:sortDescriptors];
    
    NSError *error = nil;
    NSMutableArray *mutableFetchResults = [[managedObjectContext executeFetchRequest:request error:&error] mutableCopy];
    if (mutableFetchResults == nil) {
        // Handle the error.
    }
    [self setBookmarksArray:mutableFetchResults];
    [self.tableView reloadData];
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    self.bookmarksArray = nil;
    self.addButton = nil;
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
    if (section == 1)
        return @"Onion Browser Links";
    else
        return nil;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (section == 0)
        return [bookmarksArray count];
    else
        return [[self presetBookmarks] count];
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 0)
        return YES;
    else
        return NO;
}
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = @"Cell";
    
    // Dequeue or create a new cell.
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier];
        [cell setEditingAccessoryType:UITableViewCellAccessoryDisclosureIndicator];
    }
    
    if (indexPath.section == 0) {
        Bookmark *bookmark = (Bookmark *)[bookmarksArray objectAtIndex:indexPath.row];
        cell.textLabel.text = bookmark.title;
        cell.detailTextLabel.text = bookmark.url;
        return cell;
    } else {
        NSArray *item = [[self presetBookmarks] objectAtIndex:indexPath.row];
        cell.textLabel.text = [item objectAtIndex:0];
        cell.detailTextLabel.text = [item objectAtIndex:1];
        return cell;
    }
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        
        // Delete the managed object at the given index path.
        NSManagedObject *bookmarkToDelete = [bookmarksArray objectAtIndex:indexPath.row];
        [managedObjectContext deleteObject:bookmarkToDelete];
        
        // Update the array and table view.
        [bookmarksArray removeObjectAtIndex:indexPath.row];
        [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:YES];
        // Commit the change.
        NSError *error = nil;
        if (![managedObjectContext save:&error]) {
            // Handle the error.
        }
        [self saveBookmarkOrder];
    }
}

- (void)saveBookmarkOrder {
    int16_t i = 0;
    for (Bookmark *bookmark in bookmarksArray) {
        [bookmark setOrder:i];
        i++;
    }
    NSError *error = nil;
    if (![managedObjectContext save:&error]) {
        NSLog(@"Error updating bookmark order: %@", error);
    }
}


// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath {
    
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (tableView.isEditing) {
        if (indexPath.section == 0) {
            // Open an editing pane
            Bookmark *bookmark = (Bookmark *)[bookmarksArray objectAtIndex:indexPath.row];
            BookmarkEditViewController *editController = [[BookmarkEditViewController alloc] initWithBookmark:bookmark];
            [self presentModalViewController:editController animated:YES];
        } else {
            
        }
    } else {
        NSURL *url;
        NSString *urlString;
        if (indexPath.section == 0) {
            Bookmark *bookmark = (Bookmark *)[bookmarksArray objectAtIndex:indexPath.row];
            urlString = bookmark.url;
        } else {
            NSArray *item = [[self presetBookmarks] objectAtIndex:indexPath.row];
            urlString = [item objectAtIndex:1];
        }
        AppDelegate *appDelegate = [[UIApplication sharedApplication] delegate];
        url = [NSURL URLWithString:urlString];
        [appDelegate.appWebView loadURL:url];
        [appDelegate.appWebView.addressField setText:urlString];
        [self goBack];
    }
}

- (void)addBookmark {
    Bookmark *bookmark = (Bookmark *)[NSEntityDescription insertNewObjectForEntityForName:@"Bookmark" inManagedObjectContext:managedObjectContext];
    
    [bookmark setTitle:@"Title"];
    [bookmark setUrl:@"http://example.com/"];
    
    int16_t order = [bookmarksArray count];
    [bookmark setOrder:order];
    
    NSError *error = nil;
    if (![managedObjectContext save:&error]) {
        NSLog(@"Error adding bookmark: %@", error);
    }
    [bookmarksArray addObject:bookmark];
    [self saveBookmarkOrder];

    BookmarkEditViewController *editController = [[BookmarkEditViewController alloc] initWithBookmark:bookmark];
    [self presentModalViewController:editController animated:YES];
    /*
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:order inSection:0];
    [self.tableView insertRowsAtIndexPaths:[NSArray arrayWithObject:indexPath]
                          withRowAnimation:UITableViewRowAnimationFade];
    [self.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:order inSection:0] atScrollPosition:UITableViewScrollPositionTop animated:YES];
    */
}

- (void)setEditing:(BOOL)editing animated:(BOOL)animated {
    if (editing) {
        self.navigationItem.leftBarButtonItem = editDoneButton;
        self.navigationItem.rightBarButtonItem = addButton;
    } else {
        [self saveBookmarkOrder];
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
    [self dismissModalViewControllerAnimated:YES];
}

@end
