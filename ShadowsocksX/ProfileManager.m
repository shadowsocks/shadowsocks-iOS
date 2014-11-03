//
// Created by clowwindy on 11/3/14.
// Copyright (c) 2014 clowwindy. All rights reserved.
//

#import "ProfileManager.h"

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
    } else {
        configuration = [[Configuration alloc] initWithJSONData:data];
    }
    return configuration;
}

+ (void)saveConfiguration:(Configuration *)configuration {
    [[NSUserDefaults standardUserDefaults] setObject:[configuration JSONData] forKey:CONFIG_DATA_KEY];
}

@end
