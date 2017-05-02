//
// Created by clowwindy on 11/3/14.
// Copyright (c) 2014 clowwindy. All rights reserved.
//

#import "ProfileManager.h"
#import "ShadowsocksRunner.h"

#define CONFIG_DATA_KEY @"config"

@implementation ProfileManager {

}

+ (Configuration *)configuration {
    NSData *data = [[NSUserDefaults standardUserDefaults] dataForKey:CONFIG_DATA_KEY];
    Configuration *configuration;
    if (data == nil) {
        // upgrade data from old version
        configuration = [[Configuration alloc] init];
        configuration.profiles = [[NSMutableArray alloc] initWithCapacity:16];
        if ([ShadowsocksRunner isUsingPublicServer]) {
            configuration.current = -1;
        } else {
            configuration.current = 0;
            Profile *profile = [[Profile alloc] init];
            profile.server = [ShadowsocksRunner configForKey:kShadowsocksIPKey];
            profile.serverPort = [[ShadowsocksRunner configForKey:kShadowsocksPortKey] integerValue];
            profile.password = [ShadowsocksRunner configForKey:kShadowsocksPasswordKey];
            profile.method = [ShadowsocksRunner configForKey:kShadowsocksEncryptionKey];
            [((NSMutableArray *)configuration.profiles) addObject:profile];
        }
        return configuration;
    }
    if (data == nil) {
        // load default configuration
        configuration = [[Configuration alloc] init];
        // public server
        configuration.current = -1;
        configuration.profiles = [[NSMutableArray alloc] initWithCapacity:16];
    } else {
        configuration = [[Configuration alloc] initWithJSONData:data];
    }
    return configuration;
}

+ (void)saveConfiguration:(Configuration *)configuration {
    if (configuration.profiles.count == 0) {
        configuration.current = -1;
    }
    if (configuration.current != -1 && configuration.current >= configuration.profiles.count) {
        configuration.current = 0;
    }
    [[NSUserDefaults standardUserDefaults] setObject:[configuration JSONData] forKey:CONFIG_DATA_KEY];
    [ProfileManager reloadShadowsocksRunner];
}

+ (void)reloadShadowsocksRunner {
    Configuration *configuration = [ProfileManager configuration];
    if (configuration.current == -1) {
        [ShadowsocksRunner setUsingPublicServer:YES];
        [ShadowsocksRunner reloadConfig];
    } else {
        Profile *profile = configuration.profiles[configuration.current];
        [ShadowsocksRunner setUsingPublicServer:NO];
        [ShadowsocksRunner saveConfigForKey:kShadowsocksIPKey value:profile.server];
        [ShadowsocksRunner saveConfigForKey:kShadowsocksPortKey value:[NSString stringWithFormat:@"%ld", (long)profile.serverPort]];
        [ShadowsocksRunner saveConfigForKey:kShadowsocksPasswordKey value:profile.password];
        [ShadowsocksRunner saveConfigForKey:kShadowsocksEncryptionKey value:profile.method];
        [ShadowsocksRunner reloadConfig];
    }
}

@end
