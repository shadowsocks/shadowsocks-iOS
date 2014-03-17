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

@implementation SWBAppDelegate {
    SWBConfigWindowController *configWindowController;
    NSMenuItem *statusMenuItem;
    NSMenuItem *enableMenuItem;
    BOOL isRunning;
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    [[NSAppleEventManager sharedAppleEventManager] setEventHandler:self andSelector:@selector(handleURLEvent:withReplyEvent:) forEventClass:kInternetEventClass andEventID:kAEGetURL];

    // Insert code here to initialize your application
    dispatch_queue_t proxy = dispatch_queue_create("proxy", NULL);
    dispatch_async(proxy, ^{
        [self runProxy];
    });

    NSData *pacData = [[NSData dataWithContentsOfURL:[[NSBundle mainBundle] URLForResource:@"proxy" withExtension:@"pac.gz"]] gunzippedData];
    GCDWebServer *webServer = [[GCDWebServer alloc] init];
    [webServer addHandlerForMethod:@"GET" path:@"/proxy.pac" requestClass:[GCDWebServerRequest class] processBlock:^GCDWebServerResponse *(GCDWebServerRequest *request) {
        return [GCDWebServerDataResponse responseWithData:pacData contentType:@"application/x-ns-proxy-autoconfig"];
    }
    ];

    [webServer startWithPort:8090 bonjourName:@"webserver"];

    self.item = [[NSStatusBar systemStatusBar] statusItemWithLength:20];
    self.item.image = [NSImage imageNamed:@"menu_icon"];
    self.item.highlightMode = YES;
    NSMenu *menu = [[NSMenu alloc] initWithTitle:@"Shadowsocks"];
    [menu setMinimumWidth:200];
    statusMenuItem = [[NSMenuItem alloc] initWithTitle:_L(Shadowsocks: On) action:nil keyEquivalent:@""];
//    [statusMenuItem setEnabled:NO];
    enableMenuItem = [[NSMenuItem alloc] initWithTitle:_L(Turn Shadowsocks Off) action:@selector(toggleRunning) keyEquivalent:@""];
//    [enableMenuItem setState:1];
    [menu addItem:statusMenuItem];
    [menu addItem:enableMenuItem];
    [menu addItem:[NSMenuItem separatorItem]];
    [menu addItemWithTitle:_L(Open Server Preferences...) action:@selector(showConfigWindow) keyEquivalent:@""];
    [menu addItemWithTitle:_L(Show Logs...) action:@selector(showLogs) keyEquivalent:@""];
    [menu addItemWithTitle:_L(Help) action:@selector(showHelp) keyEquivalent:@""];
    [menu addItem:[NSMenuItem separatorItem]];
    [menu addItemWithTitle:_L(Quit) action:@selector(exit) keyEquivalent:@""];
    self.item.menu = menu;
    [self installHelper];
    [self initializeProxy];

    configWindowController = [[SWBConfigWindowController alloc] initWithWindowNibName:@"ConfigWindow"];

    [self updateMenu];
}

- (void)toggleRunning {
    [self toggleSystemProxy:!isRunning];
    [[NSUserDefaults standardUserDefaults] setBool:isRunning forKey:kShadowsocksIsRunningKey];
    [self updateMenu];
}

- (void)updateMenu {
    if (isRunning) {
        statusMenuItem.title = _L(Shadowsocks: On);
        enableMenuItem.title = _L(Turn Shadowsocks Off);
        self.item.image = [NSImage imageNamed:@"menu_icon"];
//        [enableMenuItem setState:1];
    } else {
        statusMenuItem.title = _L(Shadowsocks: Off);
        enableMenuItem.title = _L(Turn Shadowsocks On);
        self.item.image = [NSImage imageNamed:@"menu_icon_disabled"];
//        [enableMenuItem setState:0];
    }
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
        [self toggleSystemProxy:NO];
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
    if (![fileManager fileExistsAtPath:kShadowsocksHelper]) {
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

- (void)initializeProxy {
    id isRunningObject = [[NSUserDefaults standardUserDefaults] objectForKey:kShadowsocksIsRunningKey];
    if ((isRunningObject == nil) || [isRunningObject boolValue]) {
        [self toggleSystemProxy:YES];
    }
}

- (void)toggleSystemProxy:(BOOL)useProxy {
    isRunning = useProxy;
    NSTask *task;
    task = [[NSTask alloc] init];
    [task setLaunchPath:kShadowsocksHelper];
    NSString *param;
    if (useProxy) {
        param = @"on";
    } else {
        param = @"off";
    }

    NSArray *arguments;
    NSLog(@"run shadowsocks helper: %@", kShadowsocksHelper);
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
