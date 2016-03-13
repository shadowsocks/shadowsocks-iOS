/*
 * Copyright 2012 ZXing authors
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

#import "ZXCharacterSetECI.h"
#import "ZXECI.h"

@implementation ZXECI

- (id)initWithValue:(int)value {
  if (self = [super init]) {
    _value = value;
  }

  return self;
}

+ (ZXECI *)eciByValue:(int)value {
  if (value < 0 || value > 999999) {
    @throw [NSException exceptionWithName:NSInvalidArgumentException
                                   reason:[NSString stringWithFormat:@"Bad ECI value: %d", value]
                                 userInfo:nil];
  }
  if (value < 900) {
    return [ZXCharacterSetECI characterSetECIByValue:value];
  }
  return nil;
}

@end
