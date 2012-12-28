//
//  AppDelegate.h
//  OnionBrowser
//
//  Copyright (c) 2012 Mike Tigas. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "WebViewController.h"
//#import "TorController.h"

#define DNT_HEADER_UNSET 0
#define DNT_HEADER_CANTRACK 1
#define DNT_HEADER_NOTRACK 2

#define UA_SPOOF_NO 0
#define UA_SPOOF_WIN7_TORBROWSER 1
#define UA_SPOOF_SAFARI_MAC 2

@interface AppDelegate : UIResponder <UIApplicationDelegate>

//@property (strong, nonatomic) TorController *tor;

@property (strong, nonatomic) UIWindow *window;

@property (readonly, strong, nonatomic) NSManagedObjectContext *managedObjectContext;
@property (readonly, strong, nonatomic) NSManagedObjectModel *managedObjectModel;
@property (readonly, strong, nonatomic) NSPersistentStoreCoordinator *persistentStoreCoordinator;

@property (nonatomic) WebViewController *appWebView;

@property (nonatomic) Byte spoofUserAgent;
@property (nonatomic) Byte dntHeader;
@property (nonatomic) Boolean usePipelining;

@property (nonatomic) NSMutableArray *sslWhitelistedDomains; // for self-signed

@property (nonatomic) Boolean doPrepopulateBookmarks;

@property (strong, nonatomic) NSThread *proxyThread;

- (void)updateTorrc;
- (NSURL *)applicationDocumentsDirectory;
- (void)runProxy;

@end
