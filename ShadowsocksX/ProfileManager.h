//
// Created by clowwindy on 11/3/14.
// Copyright (c) 2014 clowwindy. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Configuration.h"

@interface ProfileManager : NSObject

+ (Configuration *)configuration;
+ (void)saveConfiguration:(Configuration *)configuration;
+ (void)reloadShadowsocksRunner;

@end