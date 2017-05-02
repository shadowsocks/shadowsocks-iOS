//
//  SWBAppDelegate.m
//  ShadowsocksX
//
//  Created by clowwindy on 14-2-19.
//  Copyright (c) 2014年 clowwindy. All rights reserved.
//

#import "GZIP.h"
#import "SWBConfigWindowController.h"
#import "SWBQRCodeWindowController.h"
#import "SWBAppDelegate.h"
#import "GCDWebServer.h"
#import "ShadowsocksRunner.h"
#import "ProfileManager.h"
#import "AFNetworking.h"

#define kShadowsocksIsRunningKey @"ShadowsocksIsRunning"
#define kShadowsocksRunningModeKey @"ShadowsocksMode"
#define kShadowsocksHelper @"/Library/Application Support/ShadowsocksX/shadowsocks_sysconf"
#define kSysconfVersion @"1.0.0"

@implementation SWBAppDelegate {
    SWBConfigWindowController *configWindowController;
    SWBQRCodeWindowController *qrCodeWindowController;
    NSMenuItem *statusMenuItem;
    NSMenuItem *enableMenuItem;
    NSMenuItem *autoMenuItem;
    NSMenuItem *globalMenuItem;
    NSMenuItem *qrCodeMenuItem;
    NSMenu *serversMenu;
    BOOL isRunning;
    NSString *runningMode;
    NSData *originalPACData;
    FSEventStreamRef fsEventStream;
    NSString *configPath;
    NSString *PACPath;
    NSString *userRulePath;
    AFHTTPRequestOperationManager *manager;
}

static SWBAppDelegate *appDelegate;

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    [[NSAppleEventManager sharedAppleEventManager] setEventHandler:self andSelector:@selector(handleURLEvent:withReplyEvent:) forEventClass:kInternetEventClass andEventID:kAEGetURL];

    // Insert code here to initialize your application
    dispatch_queue_t proxy = dispatch_queue_create("proxy", NULL);
    dispatch_async(proxy, ^{
        [self runProxy];
    });

    originalPACData = [[NSData dataWithContentsOfURL:[[NSBundle mainBundle] URLForResource:@"proxy" withExtension:@"pac.gz"]] gunzippedData];
    GCDWebServer *webServer = [[GCDWebServer alloc] init];
    [webServer addHandlerForMethod:@"GET" path:@"/proxy.pac" requestClass:[GCDWebServerRequest class] processBlock:^GCDWebServerResponse *(GCDWebServerRequest *request) {
        return [GCDWebServerDataResponse responseWithData:[self PACData] contentType:@"application/x-ns-proxy-autoconfig"];
    }
    ];

    [webServer startWithPort:8090 bonjourName:@"webserver"];

    manager = [AFHTTPRequestOperationManager manager];
    manager.responseSerializer = [AFHTTPResponseSerializer serializer];

    self.item = [[NSStatusBar systemStatusBar] statusItemWithLength:20];
    NSImage *image = [NSImage imageNamed:@"menu_icon"];
    [image setTemplate:YES];
    self.item.image = image;
    self.item.highlightMode = YES;
    
    NSMenu *menu = [[NSMenu alloc] initWithTitle:@"Shadowsocks"];
    [menu setMinimumWidth:200];
    
    statusMenuItem = [[NSMenuItem alloc] initWithTitle:_L(Shadowsocks Off) action:nil keyEquivalent:@""];
    
    enableMenuItem = [[NSMenuItem alloc] initWithTitle:_L(Turn Shadowsocks Off) action:@selector(toggleRunning) keyEquivalent:@""];
//    [statusMenuItem setEnabled:NO];
    autoMenuItem = [[NSMenuItem alloc] initWithTitle:_L(Auto Proxy Mode) action:@selector(enableAutoProxy) keyEquivalent:@""];
//    [enableMenuItem setState:1];
    globalMenuItem = [[NSMenuItem alloc] initWithTitle:_L(Global Mode) action:@selector(enableGlobal)
        keyEquivalent:@""];
    
    [menu addItem:statusMenuItem];
    [menu addItem:enableMenuItem];
    [menu addItem:[NSMenuItem separatorItem]];
    [menu addItem:autoMenuItem];
    [menu addItem:globalMenuItem];
    
    [menu addItem:[NSMenuItem separatorItem]];

    serversMenu = [[NSMenu alloc] init];
    NSMenuItem *serversItem = [[NSMenuItem alloc] init];
    [serversItem setTitle:_L(Servers)];
    [serversItem setSubmenu:serversMenu];
    [menu addItem:serversItem];

    [menu addItem:[NSMenuItem separatorItem]];
    [menu addItemWithTitle:_L(Edit PAC for Auto Proxy Mode...) action:@selector(editPAC) keyEquivalent:@""];
    [menu addItemWithTitle:_L(Update PAC from GFWList) action:@selector(updatePACFromGFWList) keyEquivalent:@""];
    [menu addItemWithTitle:_L(Edit User Rule for GFWList...) action:@selector(editUserRule) keyEquivalent:@""];
    [menu addItem:[NSMenuItem separatorItem]];
    qrCodeMenuItem = [[NSMenuItem alloc] initWithTitle:_L(Generate QR Code...) action:@selector(showQRCode) keyEquivalent:@""];
    [menu addItem:qrCodeMenuItem];
    [menu addItem:[[NSMenuItem alloc] initWithTitle:_L(Scan QR Code from Screen...) action:@selector(scanQRCode) keyEquivalent:@""]];
    [menu addItem:[NSMenuItem separatorItem]];
    [menu addItemWithTitle:_L(Show Logs...) action:@selector(showLogs) keyEquivalent:@""];
    [menu addItemWithTitle:_L(Help) action:@selector(showHelp) keyEquivalent:@""];
    [menu addItem:[NSMenuItem separatorItem]];
    [menu addItemWithTitle:_L(Quit) action:@selector(exit) keyEquivalent:@""];
    self.item.menu = menu;
    [self installHelper];
    [self initializeProxy];


    [self updateMenu];

    configPath = [NSString stringWithFormat:@"%@/%@", NSHomeDirectory(), @".ShadowsocksX"];
    PACPath = [NSString stringWithFormat:@"%@/%@", configPath, @"gfwlist.js"];
    userRulePath = [NSString stringWithFormat:@"%@/%@", configPath, @"user-rule.txt"];
    [self monitorPAC:configPath];
    appDelegate = self;
}

- (NSData *)PACData {
    if ([[NSFileManager defaultManager] fileExistsAtPath:PACPath]) {
        return [NSData dataWithContentsOfFile:PACPath];
    } else {
        return originalPACData;
    }
}

- (void)enableAutoProxy {
    runningMode = @"auto";
    [[NSUserDefaults standardUserDefaults] setValue:runningMode forKey:kShadowsocksRunningModeKey];
    [self updateMenu];
    [self reloadSystemProxy];
}

- (void)enableGlobal {
    runningMode = @"global";
    [[NSUserDefaults standardUserDefaults] setValue:runningMode forKey:kShadowsocksRunningModeKey];
    [self updateMenu];
    [self reloadSystemProxy];
}

- (void)chooseServer:(id)sender {
    NSInteger tag = [sender tag];
    Configuration *configuration = [ProfileManager configuration];
    if (tag == -1 || tag < configuration.profiles.count) {
        configuration.current = tag;
    }
    [ProfileManager saveConfiguration:configuration];
    [self updateServersMenu];
}

- (void)updateServersMenu {
    Configuration *configuration = [ProfileManager configuration];
    [serversMenu removeAllItems];
    int i = 0;
    NSMenuItem *publicItem = [[NSMenuItem alloc] initWithTitle:_L(Public Server) action:@selector(chooseServer:) keyEquivalent:@""];
    publicItem.tag = -1;
    if (-1 == configuration.current) {
        [publicItem setState:1];
    }
    [serversMenu addItem:publicItem];
    for (Profile *profile in configuration.profiles) {
        NSString *title;
        if (profile.remarks.length) {
            title = [NSString stringWithFormat:@"%@ (%@:%d)", profile.remarks, profile.server, (int)profile.serverPort];
        } else {
            title = [NSString stringWithFormat:@"%@:%d", profile.server, (int)profile.serverPort];
        }
        NSMenuItem *item = [[NSMenuItem alloc] initWithTitle:title action:@selector(chooseServer:) keyEquivalent:@""];
        item.tag = i;
        if (i == configuration.current) {
            [item setState:1];
        }
        [serversMenu addItem:item];
        i++;
    }
    [serversMenu addItem:[NSMenuItem separatorItem]];
    [serversMenu addItemWithTitle:_L(Open Server Preferences...) action:@selector(showConfigWindow) keyEquivalent:@""];
}

- (void)updateMenu {
    if (isRunning) {
        statusMenuItem.title = _L(Shadowsocks: On);
        enableMenuItem.title = _L(Turn Shadowsocks Off);
        NSImage *image = [NSImage imageNamed:@"menu_icon"];
        [image setTemplate:YES];
        self.item.image = image;
    } else {
        statusMenuItem.title = _L(Shadowsocks: Off);
        enableMenuItem.title = _L(Turn Shadowsocks On);
        NSImage *image = [NSImage imageNamed:@"menu_icon_disabled"];
        [image setTemplate:YES];
        self.item.image = image;
    }
    
    if ([runningMode isEqualToString:@"auto"]) {
        [autoMenuItem setState:1];
        [globalMenuItem setState:0];
    } else if([runningMode isEqualToString:@"global"]) {
        [autoMenuItem setState:0];
        [globalMenuItem setState:1];
    }
    if ([ShadowsocksRunner isUsingPublicServer]) {
        [qrCodeMenuItem setTarget:nil];
        [qrCodeMenuItem setAction:NULL];
    } else {
        [qrCodeMenuItem setTarget:self];
        [qrCodeMenuItem setAction:@selector(showQRCode)];
    }
    [self updateServersMenu];
}

void onPACChange(
                ConstFSEventStreamRef streamRef,
                void *clientCallBackInfo,
                size_t numEvents,
                void *eventPaths,
                const FSEventStreamEventFlags eventFlags[],
                const FSEventStreamEventId eventIds[])
{
    [appDelegate reloadSystemProxy];
}

- (void)reloadSystemProxy {
    if (isRunning) {
        [self toggleSystemProxy:NO];
        [self toggleSystemProxy:YES];
    }
}

- (void)monitorPAC:(NSString *)pacPath {
    if (fsEventStream) {
        return;
    }
    CFStringRef mypath = (__bridge CFStringRef)(pacPath);
    CFArrayRef pathsToWatch = CFArrayCreate(NULL, (const void **)&mypath, 1, NULL);
    void *callbackInfo = NULL; // could put stream-specific data here.
    CFAbsoluteTime latency = 3.0; /* Latency in seconds */

    /* Create the stream, passing in a callback */
    fsEventStream = FSEventStreamCreate(NULL,
            &onPACChange,
            callbackInfo,
            pathsToWatch,
            kFSEventStreamEventIdSinceNow, /* Or a previous event ID */
            latency,
            kFSEventStreamCreateFlagNone /* Flags explained in reference */
    );
    FSEventStreamScheduleWithRunLoop(fsEventStream, [[NSRunLoop mainRunLoop] getCFRunLoop], (__bridge CFStringRef)NSDefaultRunLoopMode);
    FSEventStreamStart(fsEventStream);
}

- (void)editPAC {

    if (![[NSFileManager defaultManager] fileExistsAtPath:PACPath]) {
        NSError *error = nil;
        [[NSFileManager defaultManager] createDirectoryAtPath:configPath withIntermediateDirectories:NO attributes:nil error:&error];
        // TODO check error
        [originalPACData writeToFile:PACPath atomically:YES];
    }
    [self monitorPAC:configPath];
    
    NSArray *fileURLs = @[[NSURL fileURLWithPath:PACPath]];
    [[NSWorkspace sharedWorkspace] activateFileViewerSelectingURLs:fileURLs];
}


- (void)editUserRule {
  
  if (![[NSFileManager defaultManager] fileExistsAtPath:userRulePath]) {
    NSError *error = nil;
    [[NSFileManager defaultManager] createDirectoryAtPath:configPath withIntermediateDirectories:NO attributes:nil error:&error];
    // TODO check error
    [@"! Put user rules line by line in this file.\n! See https://adblockplus.org/en/filter-cheatsheet\n" writeToFile:userRulePath atomically:YES encoding:NSUTF8StringEncoding error:&error];
  }
  
  NSArray *fileURLs = @[[NSURL fileURLWithPath:userRulePath]];
  [[NSWorkspace sharedWorkspace] activateFileViewerSelectingURLs:fileURLs];
}

- (void)showQRCode {
    NSURL *qrCodeURL = [ShadowsocksRunner generateSSURL];
    if (qrCodeURL) {
        qrCodeWindowController = [[SWBQRCodeWindowController alloc] initWithWindowNibName:@"QRCodeWindow"];
        qrCodeWindowController.qrCode = [qrCodeURL absoluteString];
        [qrCodeWindowController showWindow:self];
        [NSApp activateIgnoringOtherApps:YES];
        [qrCodeWindowController.window makeKeyAndOrderFront:nil];
    } else {
        // TODO
    }
}

- (void)showLogs {
    [[NSWorkspace sharedWorkspace] launchApplication:@"/Applications/Utilities/Console.app"];
}

- (void)showHelp {
    [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:NSLocalizedString(@"https://github.com/shadowsocks/shadowsocks-iOS/wiki/Shadowsocks-for-OSX-Help", nil)]];
}

- (void)showConfigWindow {
    if (configWindowController) {
        [configWindowController close];
    }
    configWindowController = [[SWBConfigWindowController alloc] initWithWindowNibName:@"ConfigWindow"];
    configWindowController.delegate = self;
    [configWindowController showWindow:self];
    [NSApp activateIgnoringOtherApps:YES];
    [configWindowController.window makeKeyAndOrderFront:nil];
}

- (void)applicationWillTerminate:(NSNotification *)notification {
    NSLog(@"terminating");
    if (isRunning) {
        [self toggleSystemProxy:NO];
    }
}

- (void)configurationDidChange {
    [self updateMenu];
}

- (void)runProxy {
    [ShadowsocksRunner reloadConfig];
    for (; ;) {
        if ([ShadowsocksRunner runProxy]) {
            sleep(1);
        } else {
            sleep(2);
        }
    }
}

- (void)exit {
    [[NSApplication sharedApplication] terminate:nil];
}

- (void)installHelper {
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if (![fileManager fileExistsAtPath:kShadowsocksHelper] || ![self isSysconfVersionOK]) {
        NSString *helperPath = [NSString stringWithFormat:@"%@/%@", [[NSBundle mainBundle] resourcePath], @"install_helper.sh"];
        NSLog(@"run install script: %@", helperPath);
        NSDictionary *error;
        NSString *script = [NSString stringWithFormat:@"do shell script \"bash %@\" with administrator privileges", helperPath];
        NSAppleScript *appleScript = [[NSAppleScript new] initWithSource:script];
        if ([appleScript executeAndReturnError:&error]) {
            NSLog(@"installation success");
        } else {
            NSLog(@"installation failure");
        }
    }
}

- (BOOL)isSysconfVersionOK {
    NSTask *task;
    task = [[NSTask alloc] init];
    [task setLaunchPath:kShadowsocksHelper];
    
    NSArray *args;
    args = [NSArray arrayWithObjects:@"-v", nil];
    [task setArguments: args];
    
    NSPipe *pipe;
    pipe = [NSPipe pipe];
    [task setStandardOutput:pipe];
    
    NSFileHandle *fd;
    fd = [pipe fileHandleForReading];
    
    [task launch];
    
    NSData *data;
    data = [fd readDataToEndOfFile];
    
    NSString *str;
    str = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    
    if (![str isEqualToString:kSysconfVersion]) {
        return NO;
    }
    return YES;
}

- (void)initializeProxy {
    runningMode = [self runningMode];
    id isRunningObject = [[NSUserDefaults standardUserDefaults] objectForKey:kShadowsocksIsRunningKey];
    if ((isRunningObject == nil) || [isRunningObject boolValue]) {
        [self toggleSystemProxy:YES];
    }
    [self updateMenu];
}

- (void)toggleRunning {
    [self toggleSystemProxy:!isRunning];
    [[NSUserDefaults standardUserDefaults] setBool:isRunning forKey:kShadowsocksIsRunningKey];
    [self updateMenu];
}

- (NSString *)runningMode {
    NSString *mode = [[NSUserDefaults standardUserDefaults] stringForKey:kShadowsocksRunningModeKey];
    if (mode) {
        return mode;
    }
    return @"auto";
}

- (void)toggleSystemProxy:(BOOL)useProxy {
    isRunning = useProxy;
    
    NSTask *task;
    task = [[NSTask alloc] init];
    [task setLaunchPath:kShadowsocksHelper];

    NSString *param;
    if (useProxy) {
        param = [self runningMode];
    } else {
        param = @"off";
    }

    // this log is very important
    NSLog(@"run shadowsocks helper: %@", kShadowsocksHelper);
    NSArray *arguments;
    arguments = [NSArray arrayWithObjects:param, nil];
    [task setArguments:arguments];

    NSPipe *stdoutpipe;
    stdoutpipe = [NSPipe pipe];
    [task setStandardOutput:stdoutpipe];

    NSPipe *stderrpipe;
    stderrpipe = [NSPipe pipe];
    [task setStandardError:stderrpipe];

    NSFileHandle *file;
    file = [stdoutpipe fileHandleForReading];

    [task launch];

    NSData *data;
    data = [file readDataToEndOfFile];

    NSString *string;
    string = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    if (string.length > 0) {
        NSLog(@"%@", string);
    }

    file = [stderrpipe fileHandleForReading];
    data = [file readDataToEndOfFile];
    string = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    if (string.length > 0) {
        NSLog(@"%@", string);
    }
}

- (void)updatePACFromGFWList {
    [manager GET:@"https://autoproxy-gfwlist.googlecode.com/svn/trunk/gfwlist.txt" parameters:nil success:^(AFHTTPRequestOperation *operation, id responseObject) {
        // Objective-C is bullshit
        NSData *data = responseObject;
        NSString *str = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
        NSData *data2 = [[NSData alloc] initWithBase64Encoding:str];
        if (!data2) {
            NSLog(@"can't decode base64 string");
            return;
        }
        // Objective-C is bullshit
        NSString *str2 = [[NSString alloc] initWithData:data2 encoding:NSUTF8StringEncoding];
        NSArray *lines = [str2 componentsSeparatedByCharactersInSet:[NSCharacterSet newlineCharacterSet]];
        
        NSString *str3 = [[NSString alloc] initWithContentsOfFile:userRulePath encoding:NSUTF8StringEncoding error:nil];
        if (str3) {
            NSArray *rules = [str3 componentsSeparatedByCharactersInSet:[NSCharacterSet newlineCharacterSet]];
            lines = [lines arrayByAddingObjectsFromArray:rules];
        }
        
        NSMutableArray *filtered = [[NSMutableArray alloc] init];
        for (NSString *line in lines) {
            if ([line length] > 0) {
                unichar s = [line characterAtIndex:0];
                if (s == '!' || s == '[') {
                    continue;
                }
                [filtered addObject:line];
            }
        }
        // Objective-C is bullshit
        NSError *error = nil;
        NSData *jsonData = [NSJSONSerialization dataWithJSONObject:filtered options:NSJSONWritingPrettyPrinted error:&error];
        NSString *rules = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
        NSData *data3 = [NSData dataWithContentsOfURL:[[NSBundle mainBundle] URLForResource:@"abp" withExtension:@"js"]];
        NSString *template = [[NSString alloc] initWithData:data3 encoding:NSUTF8StringEncoding];
        NSString *result = [template stringByReplacingOccurrencesOfString:@"__RULES__" withString:rules];
        [[result dataUsingEncoding:NSUTF8StringEncoding] writeToFile:PACPath atomically:YES];
        NSAlert *alert = [[NSAlert alloc] init];
        alert.messageText = @"Updated";
        [alert runModal];
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"Error: %@", error);
        NSAlert *alert = [NSAlert alertWithError:error];
        [alert runModal];
    }];
}

- (void)handleURLEvent:(NSAppleEventDescriptor *)event withReplyEvent:(NSAppleEventDescriptor *)replyEvent {
    NSString *url = [[event paramDescriptorForKeyword:keyDirectObject] stringValue];
    NSAlert *alert = [[NSAlert alloc] init];
    [alert addButtonWithTitle:_L(OK)];
    [alert addButtonWithTitle:_L(Cancel)];
    [alert setMessageText:_L(Use this server?)];
    [alert setInformativeText:url];
    [alert setAlertStyle:NSInformationalAlertStyle];
    if ([alert runModal] == NSAlertFirstButtonReturn) {
        BOOL result = [ShadowsocksRunner openSSURL:[NSURL URLWithString:url]];
        if (!result) {
            alert = [[NSAlert alloc] init];
            [alert addButtonWithTitle:_L(OK)];
            [alert setMessageText:@"Invalid Shadowsocks URL"];
            [alert setAlertStyle:NSCriticalAlertStyle];
            [alert runModal];
        }
    }
}


@end
