//
//  SWBAppDelegate.m
//  ShadowsocksX
//
//  Created by clowwindy on 14-2-19.
//  Copyright (c) 2014年 clowwindy. All rights reserved.
//

#import "GZIP.h"
#import "SWBConfigWindowController.h"
#import "SWBAppDelegate.h"
#import "GCDWebServer.h"
#import "ShadowsocksRunner.h"

#define kShadowsocksIsRunningKey @"ShadowsocksIsRunning"
#define kShadowsocksHelper @"/Library/Application Support/ShadowsocksX/shadowsocks_sysconf"
#define kSysconfVersion @"1.0.0"

@implementation SWBAppDelegate {
    SWBConfigWindowController *configWindowController;
    NSMenuItem *statusMenuItem;
    NSMenuItem *enableMenuItem;
    NSMenuItem *autoMenuItem;
    NSMenuItem *globalMenuItem;
    BOOL isRunning;
    NSString *runningMode;
    NSData *originalPACData;
    FSEventStreamRef fsEventStream;
    NSString *configPath;
    NSString *PACPath;
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

    self.item = [[NSStatusBar systemStatusBar] statusItemWithLength:20];
    self.item.image = [NSImage imageNamed:@"menu_icon"];
    self.item.highlightMode = YES;
    NSMenu *menu = [[NSMenu alloc] initWithTitle:@"Shadowsocks"];
    [menu setMinimumWidth:200];
    
    statusMenuItem = [[NSMenuItem alloc] initWithTitle:_L(Shadowsocks Off) action:nil keyEquivalent:@""];
    
    enableMenuItem = [[NSMenuItem alloc] initWithTitle:_L(Turn Shadowsocks Off) action:@selector(enableProxy) keyEquivalent:@""];
//    [statusMenuItem setEnabled:NO];
    autoMenuItem = [[NSMenuItem alloc] initWithTitle:_L(Use Shadowsocks Auto Proxy Mode) action:@selector(enableAutoProxy) keyEquivalent:@""];
//    [enableMenuItem setState:1];
    globalMenuItem = [[NSMenuItem alloc] initWithTitle:_L(Use Shadowsocks Global Mode) action:@selector(enableGlobal)
        keyEquivalent:@""];
    
    [menu addItem:statusMenuItem];
    [menu addItem:enableMenuItem];
    [menu addItem:[NSMenuItem separatorItem]];
    [menu addItem:autoMenuItem];
    [menu addItem:globalMenuItem];
    
    [menu addItem:[NSMenuItem separatorItem]];
    [menu addItemWithTitle:_L(Open Server Preferences...) action:@selector(showConfigWindow) keyEquivalent:@""];
    [menu addItemWithTitle:_L(Edit PAC...) action:@selector(editPAC) keyEquivalent:@""];
    [menu addItemWithTitle:_L(Show Logs...) action:@selector(showLogs) keyEquivalent:@""];
    [menu addItemWithTitle:_L(Help) action:@selector(showHelp) keyEquivalent:@""];
    [menu addItem:[NSMenuItem separatorItem]];
    [menu addItemWithTitle:_L(Quit) action:@selector(exit) keyEquivalent:@""];
    self.item.menu = menu;
    [self installHelper];
    [self initializeProxy];

    configWindowController = [[SWBConfigWindowController alloc] initWithWindowNibName:@"ConfigWindow"];

    [self updateMenu];

    configPath = [NSString stringWithFormat:@"%@/%@", NSHomeDirectory(), @".ShadowsocksX"];
    PACPath = [NSString stringWithFormat:@"%@/%@", configPath, @"gfwlist.js"];
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

- (void)enableProxy {
    if (isRunning) {
        runningMode = @"off";
    } else {
        runningMode = @"auto";
    }
    isRunning = !isRunning;
    
    [self toggleSystemProxy:runningMode];
    [[NSUserDefaults standardUserDefaults] setObject:runningMode forKey:kShadowsocksIsRunningKey];
    [self updateMenu];
}

- (void)enableAutoProxy {
    isRunning = YES;
    runningMode = @"auto";
    [self toggleSystemProxy:@"auto"];
    [[NSUserDefaults standardUserDefaults] setValue:runningMode forKey:kShadowsocksIsRunningKey];
    [self updateMenu];
}

- (void)enableGlobal {
    isRunning = YES;
    runningMode = @"global";
    [self toggleSystemProxy:@"global"];
    [[NSUserDefaults standardUserDefaults] setValue:runningMode forKey:kShadowsocksIsRunningKey];
    [self updateMenu];
}

- (void)updateMenu {
    
    if (isRunning) {
        statusMenuItem.title = _L(Shadowsocks: On);
        enableMenuItem.title = _L(Turn Shadowsocks Off);
        
        if ([runningMode isEqualToString:@"auto"]) {
            self.item.image = [NSImage imageNamed:@"menu_icon"];
            [autoMenuItem setState:1];
            [globalMenuItem setState:0];
        } else {
            self.item.image = [NSImage imageNamed:@"menu_icon_global"];
            [autoMenuItem setState:0];
            [globalMenuItem setState:1];
        }
        
    } else {
        statusMenuItem.title = _L(Shadowsocks: Off);
        enableMenuItem.title = _L(Turn Shadowsocks On);
        [autoMenuItem setState: 0];
        [globalMenuItem setState: 0];
        self.item.image = [NSImage imageNamed:@"menu_icon_disabled"];
//        [enableMenuItem setState:0];
    }
    
}

void onPACChange(
                ConstFSEventStreamRef streamRef,
                void *clientCallBackInfo,
                size_t numEvents,
                void *eventPaths,
                const FSEventStreamEventFlags eventFlags[],
                const FSEventStreamEventId eventIds[])
{
    [appDelegate reloadPAC];
}

- (void)reloadPAC {
    if (isRunning) {
        [self toggleSystemProxy:@"off"];
        [self toggleSystemProxy:runningMode];
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

- (void)showLogs {
    [[NSWorkspace sharedWorkspace] launchApplication:@"/Applications/Utilities/Console.app"];
}

- (void)showHelp {
    [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:NSLocalizedString(@"https://github.com/shadowsocks/shadowsocks-iOS/wiki/Shadowsocks-for-OSX-Help", nil)]];
}

- (void)showConfigWindow {
    [configWindowController showWindow:self];
    [NSApp activateIgnoringOtherApps:YES];
    [configWindowController.window makeKeyAndOrderFront:nil];
}

- (void)applicationWillTerminate:(NSNotification *)notification {
    NSLog(@"terminating");
    if (isRunning) {
        [self toggleSystemProxy:@"off"];
    }
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
        NSAlert *alert = [[NSAlert alloc] init];
        [alert addButtonWithTitle:@"OK"];
        [alert setMessageText:@"shadowsocks helper need to be updated"];
        [alert runModal];
        return NO;
    }
    return YES;
}

- (void)initializeProxy {
    /*
    id isRunningObject = [[NSUserDefaults standardUserDefaults] objectForKey:kShadowsocksIsRunningKey];
    if ((isRunningObject == nil) || [isRunningObject boolValue]) {
        [self enableAutoProxy];
    }*/
    isRunning = YES;
    [self enableAutoProxy];
    [self updateMenu];
}

- (void)toggleSystemProxy:(NSString*)mode {
    isRunning = ([mode isEqualToString:@"auto"] || [mode isEqualToString:@"global"]);
    
    NSTask *task;
    task = [[NSTask alloc] init];
    [task setLaunchPath:kShadowsocksHelper];
    /*
    NSString *param;
    if (useProxy) {
        param = @"on";
    } else {
        param = @"off";
    }*/

    NSArray *arguments;
    //NSLog(@"run shadowsocks helper: %@", kShadowsocksHelper);
    arguments = [NSArray arrayWithObjects:mode, nil];
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
