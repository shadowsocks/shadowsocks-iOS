//
//  SWBAppDelegate.m
//  ShadowsocksX
//
//  Created by clowwindy on 14-2-19.
//  Copyright (c) 2014年 clowwindy. All rights reserved.
//

#import <SystemConfiguration/SystemConfiguration.h>
#import "SWBConfigWindowController.h"
#import "SWBAppDelegate.h"
#import "GCDWebServer.h"
#import "ShadowsocksRunner.h"

@implementation SWBAppDelegate
{
    SWBConfigWindowController *configWindowController;
    NSMenuItem *statusMenuItem;
    NSMenuItem *enableMenuItem;
    BOOL isRunning;
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    [[NSAppleEventManager sharedAppleEventManager] setEventHandler:self andSelector:@selector(handleURLEvent:withReplyEvent:) forEventClass:kInternetEventClass andEventID:kAEGetURL];

    // Insert code here to initialize your application
    dispatch_queue_t proxy = dispatch_queue_create("proxy", NULL);
    dispatch_async(proxy, ^{
        [self runProxy];
    });

    NSData *pacData = [NSData dataWithContentsOfURL:[[NSBundle mainBundle] URLForResource:@"proxy" withExtension:@"pac"]];
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
    [menu addItem:[NSMenuItem separatorItem]];
    [menu addItemWithTitle:_L(Quit) action:@selector(exit) keyEquivalent:@""];
    self.item.menu = menu;
    [self initializeProxy];

    configWindowController = [[SWBConfigWindowController alloc] initWithWindowNibName:@"ConfigWindow"];
}

- (void)toggleRunning {
    [self toggleSystemProxy:!isRunning];
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

- (void)showConfigWindow {
    [configWindowController showWindow:self];
    [NSApp activateIgnoringOtherApps:YES];
    [configWindowController.window makeKeyAndOrderFront:nil];
}

- (void)applicationWillTerminate:(NSNotification *)notification {
    NSLog(@"terminating");
    [self toggleSystemProxy:NO];
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

// From GoAgentX
// https://github.com/ohdarling/GoAgentX/blob/master/GoAgentX/GAService.m

static NSMutableDictionary *sharedContainer = nil;

static AuthorizationRef authRef;
static AuthorizationFlags authFlags;

- (void)initializeProxy {
    authFlags = kAuthorizationFlagDefaults
            | kAuthorizationFlagExtendRights
            | kAuthorizationFlagInteractionAllowed
            | kAuthorizationFlagPreAuthorize;
    OSStatus authErr = AuthorizationCreate(nil, kAuthorizationEmptyEnvironment, authFlags, &authRef);
    if (authErr != noErr) {
        authRef = nil;
    } else {
        [self toggleSystemProxy:YES];
    }
}

- (NSString *)proxiesPathOfDevice:(NSString *)devId {
    NSString *path = [NSString stringWithFormat:@"/%@/%@/%@", kSCPrefNetworkServices, devId, kSCEntNetProxies];
    return path;
}

- (void)toggleSystemProxy:(BOOL)useProxy {
    isRunning = useProxy;
    if (authRef == NULL) {
        NSLog(@"No authorization has been granted to modify network configuration");
        return;
    }

    SCPreferencesRef prefRef = SCPreferencesCreateWithAuthorization(nil, CFSTR("ShadowsocksX"), nil, authRef);

    NSDictionary *sets = (__bridge NSDictionary *)SCPreferencesGetValue(prefRef, kSCPrefNetworkServices);

    NSMutableDictionary *proxies = [[NSMutableDictionary alloc] init];
    [proxies setObject:[NSNumber numberWithInt:0] forKey:(NSString *)kCFNetworkProxiesHTTPEnable];
    [proxies setObject:[NSNumber numberWithInt:0] forKey:(NSString *)kCFNetworkProxiesHTTPSEnable];
    [proxies setObject:[NSNumber numberWithInt:0] forKey:(NSString *)kCFNetworkProxiesProxyAutoConfigEnable];
    [proxies setObject:[NSNumber numberWithInt:0] forKey:(NSString *)kCFNetworkProxiesSOCKSEnable];

    // 遍历系统中的网络设备列表，设置 AirPort 和 Ethernet 的代理
    for (NSString *key in [sets allKeys]) {
        NSMutableDictionary *dict = [sets objectForKey:key];
        NSString *hardware = [dict valueForKeyPath:@"Interface.Hardware"];
//        NSLog(@"%@", hardware);
        if ([hardware isEqualToString:@"AirPort"] || [hardware isEqualToString:@"Wi-Fi"] || [hardware isEqualToString:@"Ethernet"]) {
            if (useProxy) {
                [proxies setObject:@"http://127.0.0.1:8090/proxy.pac" forKey:(NSString *)kCFNetworkProxiesProxyAutoConfigURLString];
            }
            [proxies setObject:[NSNumber numberWithInt:useProxy] forKey:(NSString *)kCFNetworkProxiesProxyAutoConfigEnable];
            SCPreferencesPathSetValue(prefRef, (__bridge CFStringRef)[self proxiesPathOfDevice:key], (__bridge CFDictionaryRef)proxies);
        }
    }

    SCPreferencesCommitChanges(prefRef);
    SCPreferencesApplyChanges(prefRef);
    SCPreferencesSynchronize(prefRef);
}

- (void)handleURLEvent:(NSAppleEventDescriptor*)event withReplyEvent:(NSAppleEventDescriptor*)replyEvent {
    NSString* url = [[event paramDescriptorForKeyword:keyDirectObject] stringValue];
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
