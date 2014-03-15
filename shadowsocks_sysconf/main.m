//
//  main.m
//  shadowsocks_sysconf
//
//  Created by clowwindy on 14-3-15.
//  Copyright (c) 2014年 clowwindy. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <SystemConfiguration/SystemConfiguration.h>

int main(int argc, const char * argv[])
{
    if (argc != 2) {
        printf("usage: shadowsocks_sysconf on/off\n");
        return 1;
    }
    @autoreleasepool {
        BOOL on;
        if (strcmp(argv[1], "on") == 0) {
            on = YES;
        } else if (strcmp(argv[1], "off") == 0) {
            on = NO;
        } else {
            printf("usage: shadowsocks_sysconf on/off\n");
            return 1;
        }
        static AuthorizationRef authRef;
        static AuthorizationFlags authFlags;
        authFlags = kAuthorizationFlagDefaults
        | kAuthorizationFlagExtendRights
        | kAuthorizationFlagInteractionAllowed
        | kAuthorizationFlagPreAuthorize;
        OSStatus authErr = AuthorizationCreate(nil, kAuthorizationEmptyEnvironment, authFlags, &authRef);
        if (authErr != noErr) {
            authRef = nil;
        } else {
            if (authRef == NULL) {
                NSLog(@"No authorization has been granted to modify network configuration");
                return 1;
            }
            
            SCPreferencesRef prefRef = SCPreferencesCreateWithAuthorization(nil, CFSTR("Shadowsocks"), nil, authRef);
            
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
                    if (on) {
                        [proxies setObject:@"http://127.0.0.1:8090/proxy.pac" forKey:(NSString *)kCFNetworkProxiesProxyAutoConfigURLString];
                    }
                    [proxies setObject:[NSNumber numberWithInteger:(NSInteger)on] forKey:(NSString *)kCFNetworkProxiesProxyAutoConfigEnable];
                    SCPreferencesPathSetValue(prefRef, (__bridge CFStringRef)[NSString stringWithFormat:@"/%@/%@/%@", kSCPrefNetworkServices, key, kSCEntNetProxies], (__bridge CFDictionaryRef)proxies);
                }
            }
            
            SCPreferencesCommitChanges(prefRef);
            SCPreferencesApplyChanges(prefRef);
            SCPreferencesSynchronize(prefRef);
            
        }
            if (on) {
                printf("pac proxy set to on\n");
            } else {
                printf("pac proxy set to off\n");
            }

    }

    return 0;
}