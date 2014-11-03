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
    if (data == nil) {
        // TODO load data from old version
    }
    Configuration *configuration;
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
    [[NSUserDefaults standardUserDefaults] setObject:[configuration JSONData] forKey:CONFIG_DATA_KEY];
}

+ (void)reloadShadowsocksRunner {
    Configuration *configuration = [ProfileManager configuration];
    if (configuration.current == -1) {
        [ShadowsocksRunner setUsingPublicServer:YES];
    } else {
        Profile *profile = configuration.profiles[configuration.current];
        [ShadowsocksRunner setUsingPublicServer:NO];
        [ShadowsocksRunner saveConfigForKey:kShadowsocksIPKey value:profile.server];
        [ShadowsocksRunner saveConfigForKey:kShadowsocksPortKey value:[NSString stringWithFormat:@"%ld", (long)profile.serverPort]];
        [ShadowsocksRunner saveConfigForKey:kShadowsocksPasswordKey value:profile.password];
        [ShadowsocksRunner saveConfigForKey:kShadowsocksEncryptionKey value:profile.method];
    }
}

@end
