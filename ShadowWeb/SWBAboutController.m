//
// Created by clowwindy on 7/7/13.
// Copyright (c) 2013 clowwindy. All rights reserved.
//
// To change the template use AppCode | Preferences | File Templates.
//


#import "SWBAboutController.h"


@implementation SWBAboutController {

}


- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];

    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - View lifecycle

- (void)deviceOrientationDidChange:(NSNotification *)notification {
    //Obtaining the current device orientation
//    [[self tableView] reloadSections:[NSIndexSet indexSetWithIndex:1] withRowAnimation:UITableViewRowAnimationFade];
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.contentSizeForViewInPopover = CGSizeMake(320, 480);

    UIBarButtonItem *done = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(cancel)];
    self.navigationItem.rightBarButtonItem = done;

    self.tableView.scrollEnabled = NO;

    self.navigationItem.title = NSLocalizedString(@"About", nil);

    [[NSNotificationCenter defaultCenter] addObserver: self selector: @selector(deviceOrientationDidChange:) name: UIDeviceOrientationDidChangeNotification object: nil];
}

- (void)viewDidUnload
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIDeviceOrientationDidChangeNotification object:nil];

    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return YES;
}

-(void)cancel {
    [self dismissModalViewControllerAnimated:YES];
    if (self->_myPopoverController) {
        [_myPopoverController dismissPopoverAnimated:YES];
    }
}

-(void)displayComposerSheet
{
    if (![MFMailComposeViewController canSendMail]) {
        [[[UIAlertView alloc] initWithTitle:nil message:NSLocalizedString(@"Please setup an email account.",nil) delegate:nil cancelButtonTitle:NSLocalizedString(@"OK", nil) otherButtonTitles:nil, nil] show];
        return;
    }

    MFMailComposeViewController *picker = [[MFMailComposeViewController alloc] init];
    picker.mailComposeDelegate = self;
    [picker setToRecipients:[NSArray arrayWithObject:@"shadowsocks@googlegroups.com"]];

    [picker setSubject:NSLocalizedString(@"", nil)];
    UIDevice *device = [UIDevice currentDevice];
    NSString *content = [NSString stringWithFormat:@"\n\n\n\n\n\nTechnical Info:\n\n%@ %@\nDevice model: %@\nSystem Version: %@\n",
                                                   NSLocalizedString(@"Shadowsocks for iOS", nil),
                                                   [[NSBundle mainBundle] objectForInfoDictionaryKey:(NSString *)kCFBundleVersionKey],
                                                   [device model],
                                                   [device systemVersion]
    ];

    [picker setMessageBody:content isHTML:NO];

    [self presentModalViewController:picker animated:YES];
}

- (void)mailComposeController:(MFMailComposeViewController*)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError*)error
{
    [self dismissModalViewControllerAnimated:YES];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    if (section == 0) {
        return 4;
    }
    return 1;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{

    UITableViewCell *cell = [[UITableViewCell alloc] initWithFrame:CGRectMake(0, 0, 320, 40)];

    // Configure the cell...
    if (indexPath.section == 0) {
        if (indexPath.row == 0) {
            cell.textLabel.text = NSLocalizedString(@"Version", nil);
            UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 100.0f, 26.0f)];
            label.textAlignment = UITextAlignmentRight;
            label.text = [NSString stringWithFormat:@"%@", [[NSBundle mainBundle] objectForInfoDictionaryKey:(NSString *)kCFBundleVersionKey]];
            cell.accessoryView = label;
            label.textColor = [UIColor colorWithRed:0.0f green:0.3f blue:0.4f alpha:1.0f];
            label.backgroundColor = [UIColor clearColor];
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
        } else if (indexPath.row == 1) {
            cell.textLabel.text = NSLocalizedString(@"Email", nil);
        } else if (indexPath.row == 2) {
            cell.textLabel.text = NSLocalizedString(@"Visit Website", nil);
        } else if(indexPath.row == 3) {
            cell.textLabel.text = NSLocalizedString(@"Rate This App", nil);
        }
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    } else {
        NSError *error = nil;
        NSString *result = [[NSString alloc] initWithContentsOfURL:[[NSBundle mainBundle] URLForResource:@"about" withExtension:@"txt"] encoding:NSUTF8StringEncoding error:&error];
        result = [result stringByReplacingOccurrencesOfString:@"\n\n" withString:@"ADSAFSDFSF"];
        result = [result stringByReplacingOccurrencesOfString:@"\n" withString:@" "];
        result = [result stringByReplacingOccurrencesOfString:@"ADSAFSDFSF" withString:@"\n\n"];
        if (error != nil) {
            result = nil;
        }
        UITextView *textView = [[UITextView alloc] init];
        textView.frame = CGRectMake(0, 8.0f, cell.frame.size.width, cell.frame.size.height - 16.0f);
        textView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
        textView.text = result;
        textView.backgroundColor = [UIColor clearColor];
        [cell.contentView addSubview:textView];
        textView.editable = NO;
        textView.font = [UIFont fontWithName:@"Helvetica-Bold" size:12.0f];
        textView.textColor = [UIColor grayColor];
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
    }
    return cell;
}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 1) {

        UIInterfaceOrientation orientation = [[UIApplication sharedApplication] statusBarOrientation];
        return 480 - 300;
    }
    return 40;
}

-(NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    if (section == 1) {
        return NSLocalizedString(@"Legal notes:", nil);
    }
    return nil;
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == 0) {
        NSUInteger row = indexPath.row;
        if (row == 1) {
            [self displayComposerSheet];
        }
        else if (row == 2) {
            [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"https://github.com/shadowsocks/shadowsocks-iOS/"]];
        } else if(row == 3) {
            [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"https://itunes.apple.com/cn/app/shadowsocks/id665729974?ls=1&mt=8"]];
        }
        [tableView deselectRowAtIndexPath:indexPath animated:YES];
    }
}


@end